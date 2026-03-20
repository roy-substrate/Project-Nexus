import AVFoundation
import Accelerate
import os
import Synchronization

protocol PerturbationGenerator: AnyObject {
    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double)
    func updateMaskingThreshold(_ threshold: [Float])
    var isEnabled: Bool { get set }
}

final class AudioPipelineManager: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "Pipeline")

    private let engine = AVAudioEngine()
    private let sessionConfigurator = AudioSessionConfigurator.shared
    private let micCapture: MicCaptureNode
    private let perturbationMixer = PerturbationMixerNode()

    private var sourceNode: AVAudioSourceNode?
    private var generators: [PerturbationGenerator] = []
    private var mixBuffer: [Float] = []

    private(set) var isRunning = false
    private let format: AVAudioFormat
    /// Counts render-callback invocations where the output buffer pointer was nil
    /// (indicative of a buffer underrun or audio graph misconfiguration).
    /// Atomic so it can be safely incremented on the CoreAudio render thread and
    /// read on the main thread without a data race.
    private let underrunCount: Atomic<Int> = Atomic(0)

    var onMetricsUpdate: ((AudioMetrics) -> Void)?
    var onSpectrumUpdate: (([Float]) -> Void)?
    /// Set this to forward mic buffers into ASREffectivenessService.appendBuffer(_:)
    /// — avoids a second AVAudioEngine competing over AVAudioSession.
    var onMicBuffer: ((AVAudioPCMBuffer) -> Void)?

    init() throws {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1) else {
            throw AudioPipelineError.invalidFormat
        }
        format = fmt
        micCapture = try MicCaptureNode()
        // Pre-allocate to the maximum CoreAudio frame size so the render callback
        // never performs a heap allocation on the real-time audio thread.
        mixBuffer = [Float](repeating: 0, count: 4096)
        setupMicCallbacks()
        setupNotifications()
    }

    enum AudioPipelineError: LocalizedError {
        case invalidFormat
        var errorDescription: String? { "Could not create audio format (48 kHz mono)." }
    }

    func addGenerator(_ generator: PerturbationGenerator) {
        generators.append(generator)
    }

    func removeAllGenerators() {
        generators.removeAll()
    }

    func start() throws {
        guard !isRunning else { return }

        try sessionConfigurator.configure()
        try sessionConfigurator.activate()

        let sampleRate = format.sampleRate
        let gensCopy = generators

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, buffers -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(buffers)
            guard let buffer = ablPointer.first?.mData?.assumingMemoryBound(to: Float.self) else {
                self.underrunCount.add(1, ordering: .relaxed)
                return noErr
            }

            let count = Int(frameCount)

            // Clear output buffer
            memset(buffer, 0, count * MemoryLayout<Float>.size)

            // Sum all active generators
            for generator in gensCopy where generator.isEnabled {
                self.mixBuffer.withUnsafeMutableBufferPointer { mixPtr in
                    guard let mixBase = mixPtr.baseAddress else { return }
                    memset(mixBase, 0, count * MemoryLayout<Float>.size)
                    generator.fillBuffer(mixBase, frameCount: count, sampleRate: sampleRate)
                    // Vectorized element-wise addition — avoids scalar loop overhead
                    vDSP_vadd(buffer, 1, mixBase, 1, buffer, 1, vDSP_Length(count))
                }
            }

            // Soft clip via vectorized tanh (vvtanhf processes the whole buffer in one call)
            var n = Int32(count)
            vvtanhf(buffer, buffer, &n)

            return noErr
        }

        self.sourceNode = sourceNode

        engine.attach(sourceNode)
        engine.attach(perturbationMixer.mixerNode)

        engine.connect(sourceNode, to: perturbationMixer.mixerNode, format: format)
        engine.connect(perturbationMixer.mixerNode, to: engine.mainMixerNode, format: format)

        // Install mic tap for analysis
        let inputFormat = engine.inputNode.outputFormat(forBus: 0)
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            micCapture.installTap(on: engine.inputNode, bus: 0, bufferSize: 1024)
        }

        try engine.start()
        isRunning = true
        logger.info("Audio pipeline started: \(sampleRate)Hz")
    }

    func stop() {
        guard isRunning else { return }

        micCapture.removeTap(from: engine.inputNode)
        engine.stop()

        if let sourceNode {
            engine.detach(sourceNode)
        }
        engine.detach(perturbationMixer.mixerNode)
        sourceNode = nil

        sessionConfigurator.deactivate()
        isRunning = false
        underrunCount.store(0, ordering: .relaxed)
        logger.info("Audio pipeline stopped")
    }

    func setOutputGain(_ gain: Float) {
        perturbationMixer.setGain(gain)
    }

    func updateGeneratorThresholds(_ threshold: [Float]) {
        for generator in generators {
            generator.updateMaskingThreshold(threshold)
        }
    }

    private func setupMicCallbacks() {
        micCapture.onSpectrumUpdate = { [weak self] spectrum, rms, peak in
            guard let self else { return }
            var metrics = AudioMetrics()
            metrics.spectrumData = spectrum
            metrics.rmsLevel = rms
            metrics.peakLevel = peak
            metrics.isEngineRunning = self.isRunning
            metrics.latencyMs = self.sessionConfigurator.ioBufferDuration * 1000 * 2
            metrics.bufferUnderruns = self.underrunCount.load(ordering: .relaxed)

            DispatchQueue.main.async {
                self.onMetricsUpdate?(metrics)
            }

            // Forward spectrum for external processing (e.g. PsychoacousticMasker)
            self.onSpectrumUpdate?(spectrum)
        }

        // Forward raw PCM buffers to any ASR measurement consumer.
        // Eliminates the need for ASREffectivenessService to create its own AVAudioEngine.
        micCapture.onRawBuffer = { [weak self] buffer in
            self?.onMicBuffer?(buffer)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .audioSessionInterrupted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }

        NotificationCenter.default.addObserver(
            forName: .audioSessionResumed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            do {
                try self.start()
            } catch {
                self.logger.error("Pipeline failed to restart after session resume: \(error.localizedDescription)")
                // Post notification so callers (e.g. PerturbationService / UI) can react
                NotificationCenter.default.post(name: .audioPipelineRestartFailed, object: error)
            }
        }
    }
}
