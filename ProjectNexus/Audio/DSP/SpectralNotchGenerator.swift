import Foundation
import Accelerate

final class SpectralNotchGenerator: PerturbationGenerator {
    var isEnabled: Bool = true

    private let noiseTableSize = 48000  // 1 second at 48kHz
    private var noiseTable: [Float]
    private var readPosition: Int = 0
    private var currentMaskingThreshold: [Float] = []

    private let formantFrequencies: [Float] = [500, 1500, 2500]
    private let notchWidth: Float = 80
    private let lowFreq: Float = 300
    private let highFreq: Float = 4000
    private var intensity: Float = 0.8

    private let lock = os_unfair_lock_t.allocate(capacity: 1)

    init(intensity: Float = 0.8) {
        self.intensity = intensity
        self.noiseTable = DSPUtilities.generateWhiteNoise(count: noiseTableSize)
        lock.initialize(to: os_unfair_lock())
        prepareNoiseTable()
    }

    deinit {
        lock.deallocate()
    }

    func setIntensity(_ value: Float) {
        intensity = max(0, min(1, value))
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            buffer[i] = noiseTable[readPosition] * intensity * 0.15
            readPosition = (readPosition + 1) % noiseTableSize
        }
    }

    func updateMaskingThreshold(_ threshold: [Float]) {
        os_unfair_lock_lock(lock)
        currentMaskingThreshold = threshold
        os_unfair_lock_unlock(lock)
    }

    private func prepareNoiseTable() {
        // Bandpass filter to 300Hz-4kHz
        DSPUtilities.bandpassFilter(
            &noiseTable,
            lowFreq: lowFreq,
            highFreq: highFreq,
            sampleRate: 48000
        )

        // Apply spectral notches at formant frequencies
        DSPUtilities.applySpectralNotch(
            &noiseTable,
            notchFrequencies: formantFrequencies,
            notchWidth: notchWidth,
            sampleRate: 48000
        )

        // Normalize
        var peak: Float = 0
        vDSP_maxmgv(noiseTable, 1, &peak, vDSP_Length(noiseTableSize))
        if peak > 0 {
            var scale = 1.0 / peak
            vDSP_vsmul(noiseTable, 1, &scale, &noiseTable, 1, vDSP_Length(noiseTableSize))
        }

        // Apply crossfade at loop boundary (50ms crossfade)
        let crossfadeSamples = 2400
        for i in 0..<crossfadeSamples {
            let t = Float(i) / Float(crossfadeSamples)
            let fadeIn = t
            let fadeOut = 1.0 - t
            noiseTable[i] *= fadeIn
            noiseTable[noiseTableSize - crossfadeSamples + i] *= fadeOut
        }
    }
}
