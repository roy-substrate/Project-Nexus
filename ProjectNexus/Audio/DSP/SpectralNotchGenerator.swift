import Foundation
import Accelerate
import Synchronization

final class SpectralNotchGenerator: PerturbationGenerator {
    // Atomic backing so the CoreAudio render thread (read) and main thread (write)
    // can access isEnabled without a data race.
    private let _isEnabled = Atomic<Bool>(true)
    var isEnabled: Bool {
        get { _isEnabled.load(ordering: .relaxed) }
        set { _isEnabled.store(newValue, ordering: .relaxed) }
    }

    private let noiseTableSize = 48000  // 1 second at 48kHz
    private var noiseTable: [Float]
    private var readPosition: Int = 0

    private let formantFrequencies: [Float] = [500, 1500, 2500]
    private let notchWidth: Float = 80
    private var lowFreq: Float
    private var highFreq: Float
    private var intensity: Float = 0.8

    // Atomic scalar gain derived from PsychoacousticMasker thresholds.
    // Written on the main thread, read on the CoreAudio render thread — Atomic<Float>
    // avoids os_unfair_lock overhead on the hot path (CTO Option B).
    private let _maskingGain = Atomic<Float>(1.0)

    init(intensity: Float = 0.8, lowFreq: Float = 300, highFreq: Float = 4_000) {
        self.intensity = intensity
        self.lowFreq = lowFreq
        self.highFreq = highFreq
        self.noiseTable = DSPUtilities.generateWhiteNoise(count: noiseTableSize)
        prepareNoiseTable()
    }

    func setIntensity(_ value: Float) {
        intensity = max(0, min(1, value))
    }

    func setFrequencyRange(low: Float, high: Float) {
        lowFreq = low
        highFreq = high
        prepareNoiseTable()
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        // Copy from circular noise table without a scalar loop.
        // Handles wrap-around with at most two vDSP_vsmul calls.
        let scale = intensity * 0.15 * _maskingGain.load(ordering: .relaxed)
        var remaining = frameCount
        var outOffset = 0
        while remaining > 0 {
            let chunk = min(remaining, noiseTableSize - readPosition)
            noiseTable.withUnsafeBufferPointer { tablePtr in
                var s = scale
                vDSP_vsmul(tablePtr.baseAddress! + readPosition, 1,
                            &s,
                            buffer + outOffset, 1,
                            vDSP_Length(chunk))
            }
            readPosition = (readPosition + chunk) % noiseTableSize
            outOffset += chunk
            remaining -= chunk
        }
    }

    func updateMaskingThreshold(_ threshold: [Float]) {
        guard !threshold.isEmpty else { return }
        var mean: Float = 0
        vDSP_meanv(threshold, 1, &mean, vDSP_Length(threshold.count))
        let gain = max(0.05, min(1.0, (mean + 60.0) / 60.0))
        _maskingGain.store(gain, ordering: .relaxed)
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
