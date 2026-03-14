import Foundation
import os

final class PerturbationService {
    private let logger = Logger(subsystem: "com.nexus", category: "PertService")

    private let pipeline: AudioPipelineManager
    private let masker = PsychoacousticMasker()
    private let uapManager = UAPManager()
    private let speakerRouter = SpeakerPlaybackRouter()

    private var spectralNotch: SpectralNotchGenerator?
    private var babbleNoise: BabbleNoiseGenerator?
    private var frequencySweep: FrequencySweepGenerator?
    private var uapGenerator: UAPGenerator?

    var onMetricsUpdate: ((AudioMetrics) -> Void)?

    init() throws {
        pipeline = try AudioPipelineManager()
        pipeline.onMetricsUpdate = { [weak self] metrics in
            self?.onMetricsUpdate?(metrics)
        }
        uapManager.loadUAPs()
    }

    func start(with config: PerturbationConfig) throws {
        pipeline.removeAllGenerators()

        // Tier 1 generators
        if config.tier1Enabled {
            if config.isTechniqueEnabled(.spectralNotch) {
                let gen = SpectralNotchGenerator(intensity: config.intensity)
                spectralNotch = gen
                pipeline.addGenerator(gen)
            }
            if config.isTechniqueEnabled(.babbleNoise) {
                let gen = BabbleNoiseGenerator(intensity: config.intensity)
                babbleNoise = gen
                pipeline.addGenerator(gen)
            }
            if config.isTechniqueEnabled(.frequencySweep) {
                let gen = FrequencySweepGenerator(intensity: config.intensity)
                frequencySweep = gen
                pipeline.addGenerator(gen)
            }
        }

        // Tier 2 generators
        if config.tier2Enabled {
            let variant: UAPVariant
            if config.isTechniqueEnabled(.uapEnsemble) {
                variant = .ensemble
            } else if config.isTechniqueEnabled(.uapWhisper) {
                variant = .whisperOptimized
            } else if config.isTechniqueEnabled(.uapDeepSpeech) {
                variant = .deepspeechOptimized
            } else {
                variant = .ensemble
            }
            uapManager.selectVariant(variant)

            let gen = UAPGenerator(uapManager: uapManager, intensity: config.intensity)
            uapGenerator = gen
            pipeline.addGenerator(gen)
        }

        pipeline.setOutputGain(config.intensity)

        try speakerRouter.activate()
        try pipeline.start()

        logger.info("Perturbation service started")
    }

    func stop() {
        pipeline.stop()
        speakerRouter.deactivate()
        spectralNotch = nil
        babbleNoise = nil
        frequencySweep = nil
        uapGenerator = nil
        logger.info("Perturbation service stopped")
    }

    func updateConfig(_ config: PerturbationConfig) {
        pipeline.setOutputGain(config.intensity)
        spectralNotch?.setIntensity(config.intensity)
        babbleNoise?.setIntensity(config.intensity)
        frequencySweep?.setIntensity(config.intensity)

        spectralNotch?.isEnabled = config.tier1Enabled && config.isTechniqueEnabled(.spectralNotch)
        babbleNoise?.isEnabled = config.tier1Enabled && config.isTechniqueEnabled(.babbleNoise)
        frequencySweep?.isEnabled = config.tier1Enabled && config.isTechniqueEnabled(.frequencySweep)
        uapGenerator?.isEnabled = config.tier2Enabled
    }

    var isRunning: Bool { pipeline.isRunning }
}

private final class UAPGenerator: PerturbationGenerator {
    var isEnabled: Bool = true

    private let uapManager: UAPManager
    private var intensity: Float

    init(uapManager: UAPManager, intensity: Float) {
        self.uapManager = uapManager
        self.intensity = intensity
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        uapManager.fillBuffer(buffer, frameCount: frameCount, gain: intensity * 0.5)
    }

    func updateMaskingThreshold(_ threshold: [Float]) {}
}
