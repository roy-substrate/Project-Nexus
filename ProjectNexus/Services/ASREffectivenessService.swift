import Foundation
import Speech
import AVFoundation
import os

// MARK: - Effectiveness Result

/// Snapshot of a single recognition pass, with and without perturbation active.
struct ASRMeasurement: Sendable {
    /// Recognised text produced during this window.
    let transcript: String
    /// Normalised word-error-rate proxy: 0 = perfect recognition, 1 = total failure.
    /// Computed as `1 − (recognisedWords / referenceWords)`, clamped to [0, 1].
    let errorRate: Float
    /// True when the perturbation was active during this measurement window.
    let perturbationActive: Bool
    /// Wall-clock time of the measurement.
    let timestamp: Date
}

// MARK: - ASREffectivenessService

/// Measures how well the perturbation engine degrades on-device ASR in real time.
///
/// The service runs `SFSpeechRecognizer` in a continuous recognition task and
/// computes a word-error-rate proxy by comparing recognised word count against
/// a rolling reference baseline (the word count when the shield is **off**).
///
/// Usage:
/// ```swift
/// let asr = ASREffectivenessService()
/// try await asr.requestAuthorization()
/// asr.startMeasuring(isShieldActive: binding)
/// // Read asr.latestMeasurement or asr.effectivenessScore
/// ```
@Observable
final class ASREffectivenessService: NSObject {

    // MARK: - Public State

    /// Latest raw measurement (updated on main actor).
    private(set) var latestMeasurement: ASRMeasurement?

    /// Rolling effectiveness score in [0, 1].
    /// 0 = no degradation, 1 = ASR completely jammed.
    private(set) var effectivenessScore: Float = 0

    /// True after `requestAuthorization()` resolves to `.authorized`.
    private(set) var isAuthorized: Bool = false

    /// True while a recognition task is running.
    private(set) var isMeasuring: Bool = false

    /// Called on the main actor whenever `effectivenessScore` is updated.
    /// Wire this to `analyticsService.track(.asrScoreRecorded(score:))` in the app.
    var onEffectivenessUpdate: (@MainActor (Float) -> Void)?

    // MARK: - Private

    private let logger = Logger(subsystem: "com.nexus.asr", category: "Effectiveness")
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    // No separate AVAudioEngine — buffers are delivered via appendBuffer()
    // from the existing MicCaptureNode tap in AudioPipelineManager.
    // This eliminates the dual-engine AVAudioSession conflict.
    private var request: SFSpeechAudioBufferRecognitionRequest?

    /// Baseline word-per-second rate collected when shield is off (EMA).
    private var baselineWPS: Float = 1.0
    private let baselineAlpha: Float = 0.10

    /// EMA state for the effectiveness score.
    private let emaAlpha: Float = 0.20

    private var windowStart: Date = Date()
    private var wordCountInWindow: Int = 0
    private var isShieldCurrentlyActive: Bool = false

    /// Tracks consecutive restart attempts to prevent infinite recursion.
    private var restartAttempts: Int = 0
    private let maxRestartAttempts = 5

    // MARK: - Init

    override init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        recognizer?.delegate = self
    }

    // MARK: - Authorization

    /// Requests SFSpeechRecognizer authorization.  Must be called before `startMeasuring()`.
    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        isAuthorized = (status == .authorized)
        return isAuthorized
    }

    // MARK: - Measurement Lifecycle

    /// Starts the recognition loop. Buffers must be fed via `appendBuffer(_:)`.
    ///
    /// Callers should route mic buffers from the existing `MicCaptureNode` tap
    /// (inside `AudioPipelineManager`) rather than creating a second `AVAudioEngine`.
    /// This avoids `AVAudioSession` conflicts and halves audio-thread overhead.
    func startMeasuring(shieldActiveProvider: @escaping @Sendable () -> Bool) {
        guard isAuthorized, !isMeasuring else { return }
        guard let recognizer, recognizer.isAvailable else {
            logger.warning("SFSpeechRecognizer unavailable on this device/locale")
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true   // Stay fully on-device (iOS 13+)
        request = req

        windowStart = Date()
        wordCountInWindow = 0
        restartAttempts = 0
        isMeasuring = true

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let words = result.bestTranscription.formattedString
                    .split(separator: " ").count
                self.wordCountInWindow = words

                if result.isFinal {
                    self.commitWindow(shieldActive: shieldActiveProvider())
                }
            }

            if let error {
                // Recognition session ends normally after ~1 min; restart transparently.
                let nsError = error as NSError
                let isSessionEnd = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110
                if !isSessionEnd {
                    self.logger.warning("Recognition task error: \(error.localizedDescription)")
                }
                self.restartTask(shieldActiveProvider: shieldActiveProvider)
            }
        }

        logger.info("ASR effectiveness measurement started (buffer-feed mode)")
    }

    /// Feed a mic buffer into the recognition request.
    /// Call this from the MicCaptureNode tap in AudioPipelineManager — do NOT
    /// create a second AVAudioEngine for ASR.
    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func stopMeasuring() {
        guard isMeasuring else { return }
        recognitionTask?.cancel()
        recognitionTask = nil
        request?.endAudio()
        request = nil
        isMeasuring = false
        logger.info("ASR effectiveness measurement stopped")
    }

    // MARK: - Private helpers

    private func commitWindow(shieldActive: Bool) {
        let elapsed = max(0.01, Date().timeIntervalSince(windowStart))
        let wps = Float(wordCountInWindow) / Float(elapsed)

        if !shieldActive {
            // Update baseline with EMA when shield is off
            baselineWPS = baselineWPS * (1 - baselineAlpha) + wps * baselineAlpha
        }

        // Error rate: how much worse is recognition with shield vs baseline?
        let baseline = max(0.01, baselineWPS)
        let rawError = shieldActive ? max(0, 1 - (wps / baseline)) : 0

        let measurement = ASRMeasurement(
            transcript: "",
            errorRate: rawError,
            perturbationActive: shieldActive,
            timestamp: Date()
        )

        // Capture emaAlpha as a local to avoid capturing self off the main actor
        let alpha = emaAlpha
        Task { @MainActor [weak self] in
            guard let self else { return }
            let newScore = self.effectivenessScore * (1 - alpha) + rawError * alpha
            self.latestMeasurement = measurement
            self.effectivenessScore = newScore
            self.onEffectivenessUpdate?(newScore)
        }

        // Reset window
        windowStart = Date()
        wordCountInWindow = 0

        logger.debug("Window committed — WPS: \(wps, format: .fixed(precision: 2)), error: \(rawError, format: .fixed(precision: 2))")
    }

    private func restartTask(shieldActiveProvider: @escaping @Sendable () -> Bool) {
        recognitionTask?.cancel()
        recognitionTask = nil
        // End and discard the old request — SFSpeechAudioBufferRecognitionRequest
        // cannot be reused after a session ends (error 1110 or otherwise).
        request?.endAudio()
        request = nil

        guard restartAttempts < maxRestartAttempts else {
            logger.error("ASR restart limit reached (\(self.maxRestartAttempts) attempts) — stopping measurement")
            isMeasuring = false
            return
        }
        restartAttempts += 1

        guard let recognizer, isMeasuring else { return }

        // Create a fresh request for the new recognition session.
        let newReq = SFSpeechAudioBufferRecognitionRequest()
        newReq.shouldReportPartialResults = true
        newReq.requiresOnDeviceRecognition = true
        request = newReq

        recognitionTask = recognizer.recognitionTask(with: newReq) { [weak self] result, error in
            guard let self else { return }
            if let result, result.isFinal {
                self.restartAttempts = 0
                self.commitWindow(shieldActive: shieldActiveProvider())
            } else if error != nil {
                // Use else-if to prevent both branches firing when the framework
                // delivers a partial result and an error in the same callback.
                // Without this guard, restartTask() could recurse while
                // restartAttempts hasn't been reset, exhausting the retry budget.
                self.restartTask(shieldActiveProvider: shieldActiveProvider)
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension ASREffectivenessService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        logger.info("SFSpeechRecognizer availability changed: \(available)")
    }
}
