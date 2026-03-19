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
    private var currentMaskingThreshold: [Float] = []

    private let formantFrequencies: [Float] = [17_500, 18_500, 19_500]
    private let notchWidth: Float = 80
    private var lowFreq: Float
    private var highFreq: Float
    // Atomic backing so the CoreAudio render thread (read) and main thread (write via
    // setIntensity) never race on the intensity value.
    private let _intensity = Atomic<Float>(0.8)
    private var intensity: Float {
        get { _intensity.load(ordering: .relaxed) }
        set { _intensity.store(newValue, ordering: .relaxed) }
    }

    private let lock = os_unfair_lock_t.allocate(capacity: 1)

    init(intensity: Float = 0.8, lowFreq: Float = 17_000, highFreq: Float = 20_000) {
        self.intensity = max(0, min(1, intensity))
        self.lowFreq = lowFreq
        self.highFreq = highFreq
        self.noiseTable = DSPUtilities.generateWhiteNoise(count: noiseTableSize)
        lock.initialize(to: os_unfair_lock())
        prepareNoiseTable()
    }

    deinit {
        lock.deallocate()
    }

    func setIntensity(_ value: Float) {
        intensity = max(0, min(1, value))  // Atomic<Float> setter — safe cross-thread
    }

    func setFrequencyRange(low: Float, high: Float) {
        lowFreq = low
        highFreq = high
        prepareNoiseTable()
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        // Copy from circular noise table without a scalar loop.
        // Handles wrap-around with at most two vDSP_vsmul calls.
        let scale = intensity * 0.15
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
