import AVFoundation
import os

protocol PerturbationGenerator: AnyObject {
    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double)
    func updateMaskingThreshold(_ threshold: [Float])
    var isEnabled: Bool { get set }
}

final class AudioPipelineManager {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "Pipeline")

    private let engine = AVAudioEngine()
    private let sessionConfigurator = AudioSessionConfigurator.shared
    private let micCapture = MicCaptureNode()
    private let perturbationMixer = PerturbationMixerNode()

    private var sourceNode: AVAudioSourceNode?
    private var generators: [PerturbationGenerator] = []
    private var mixBuffer: [Float] = []

    private(set) var isRunning = false
    private let format: AVAudioFormat

    var onMetricsUpdate: ((AudioMetrics) -> Void)?
    var onSpectrumUpdate: (([Float]) -> Void)?

    init() {
        format = AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 1
        )!
        mixBuffer = [Float](repeating: 0, count: 1024)
        setupMicCallbacks()
        setupNotifications()
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
                return noErr
            }

            let count = Int(frameCount)

            // Clear output buffer
            memset(buffer, 0, count * MemoryLayout<Float>.size)

            // Ensure mix buffer is large enough
            if self.mixBuffer.count < count {
                self.mixBuffer = [Float](repeating: 0, count: count)
            }

            // Sum all active generators
            for generator in gensCopy where generator.isEnabled {
                self.mixBuffer.withUnsafeMutableBufferPointer { mixPtr in
                    guard let mixBase = mixPtr.baseAddress else { return }
                    memset(mixBase, 0, count * MemoryLayout<Float>.size)
                    generator.fillBuffer(mixBase, frameCount: count, sampleRate: sampleRate)

                    // Add to output
                    for i in 0..<count {
                        buffer[i] += mixBase[i]
                    }
                }
            }

            // Soft clip to prevent distortion
            for i in 0..<count {
                buffer[i] = tanhf(buffer[i])
            }

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
        logger.info("Audio pipeline stopped")
    }

    func setOutputGain(_ gain: Float) {
        perturbationMixer.setGain(gain)
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

            DispatchQueue.main.async {
                self.onMetricsUpdate?(metrics)
            }

            // Feed masking threshold to generators
            for generator in self.generators {
                generator.updateMaskingThreshold(spectrum)
            }
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
            try? self?.start()
        }
    }
}
