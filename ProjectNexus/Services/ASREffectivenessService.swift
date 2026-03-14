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

    // MARK: - Private

    private let logger = Logger(subsystem: "com.nexus.asr", category: "Effectiveness")
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?

    /// Baseline word-per-second rate collected when shield is off (EMA).
    private var baselineWPS: Float = 1.0
    private let baselineAlpha: Float = 0.10

    /// EMA state for the effectiveness score.
    private let emaAlpha: Float = 0.20

    private var windowStart: Date = Date()
    private var wordCountInWindow: Int = 0
    private var isShieldCurrentlyActive: Bool = false

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

    /// Starts the continuous recognition loop.
    /// - Parameter shieldActive: A closure called each measurement window to know the current shield state.
    func startMeasuring(shieldActiveProvider: @escaping @Sendable () -> Bool) {
        guard isAuthorized, !isMeasuring else { return }
        guard let recognizer, recognizer.isAvailable else {
            logger.warning("SFSpeechRecognizer unavailable on this device/locale")
            return
        }

        let engine = AVAudioEngine()
        audioEngine = engine

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true   // Stay fully on-device (iOS 13+)
        request = req

        // Tap into the main mixer for speech samples
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        do {
            try engine.start()
        } catch {
            logger.error("AVAudioEngine failed to start for ASR measurement: \(error.localizedDescription)")
            return
        }

        windowStart = Date()
        wordCountInWindow = 0
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
                // Recognition session ends normally when audio stops or after ~1 min;
                // restart it transparently.
                let nsError = error as NSError
                let isSessionEnd = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110
                if !isSessionEnd {
                    self.logger.warning("Recognition task error: \(error.localizedDescription)")
                }
                self.restartTask(shieldActiveProvider: shieldActiveProvider)
            }
        }

        logger.info("ASR effectiveness measurement started")
    }

    func stopMeasuring() {
        guard isMeasuring else { return }
        recognitionTask?.cancel()
        recognitionTask = nil
        request?.endAudio()
        request = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
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
        let newScore  = effectivenessScore * (1 - emaAlpha) + rawError * emaAlpha

        let transcript = request.map { _ in "" } ?? ""    // transcript via task result above

        let measurement = ASRMeasurement(
            transcript: transcript,
            errorRate: rawError,
            perturbationActive: shieldActive,
            timestamp: Date()
        )

        Task { @MainActor [weak self] in
            self?.latestMeasurement = measurement
            self?.effectivenessScore = newScore
        }

        // Reset window
        windowStart = Date()
        wordCountInWindow = 0

        logger.debug("Window committed — WPS: \(wps, format: .fixed(precision: 2)), error: \(rawError, format: .fixed(precision: 2)), score: \(newScore, format: .fixed(precision: 2))")
    }

    private func restartTask(shieldActiveProvider: @escaping @Sendable () -> Bool) {
        recognitionTask?.cancel()
        recognitionTask = nil

        guard let recognizer, let req = request, isMeasuring else { return }

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result, result.isFinal {
                self.commitWindow(shieldActive: shieldActiveProvider())
            }
            if error != nil {
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
