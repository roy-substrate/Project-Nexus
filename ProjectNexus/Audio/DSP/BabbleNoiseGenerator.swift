import Foundation
import Accelerate
import Synchronization

final class BabbleNoiseGenerator: PerturbationGenerator {
    private let _isEnabled = Atomic<Bool>(true)
    var isEnabled: Bool {
        get { _isEnabled.load(ordering: .relaxed) }
        set { _isEnabled.store(newValue, ordering: .relaxed) }
    }

    private let layerCount = 4
    private let segmentLength = 48000 * 3  // 3 seconds at 48kHz
    private var layers: [[Float]] = []
    private var layerPositions: [Int] = []
    private var layerGains: [Float] = []
    private var intensity: Float = 0.8

    private var lowFreq: Float
    private var highFreq: Float

    // Atomic scalar gain derived from PsychoacousticMasker thresholds (CTO Option B).
    private let _maskingGain = Atomic<Float>(1.0)

    init(intensity: Float = 0.8, lowFreq: Float = 300, highFreq: Float = 4_000) {
        self.intensity = intensity
        self.lowFreq = lowFreq
        self.highFreq = highFreq
        generateBabbleLayers()
    }

    func setIntensity(_ value: Float) {
        intensity = max(0, min(1, value))
    }

    func setFrequencyRange(low: Float, high: Float) {
        lowFreq = low
        highFreq = high
        generateBabbleLayers()
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        // Clear output buffer, then accumulate each layer with vectorized ops.
        memset(buffer, 0, frameCount * MemoryLayout<Float>.size)

        for l in 0..<layerCount {
            guard l < layers.count else { continue }
            let layer = layers[l]
            let layerLen = layer.count
            var pos = layerPositions[l]
            var gain = layerGains[l] * intensity * 0.12 * _maskingGain.load(ordering: .relaxed)

            layer.withUnsafeBufferPointer { layerPtr in
                guard let base = layerPtr.baseAddress else { return }
                var remaining = frameCount
                var outOffset = 0
                while remaining > 0 {
                    let chunk = min(remaining, layerLen - pos)
                    // Vectorized scale-and-accumulate: buffer += layer[pos..] * gain
                    vDSP_vsma(base + pos, 1, &gain, buffer + outOffset, 1,
                              buffer + outOffset, 1, vDSP_Length(chunk))
                    pos = (pos + chunk) % layerLen
                    outOffset += chunk
                    remaining -= chunk
                }
            }
            layerPositions[l] = pos
        }
    }

    func updateMaskingThreshold(_ threshold: [Float]) {
        guard !threshold.isEmpty else { return }
        var mean: Float = 0
        vDSP_meanv(threshold, 1, &mean, vDSP_Length(threshold.count))
        let gain = max(0.05, min(1.0, (mean + 60.0) / 60.0))
        _maskingGain.store(gain, ordering: .relaxed)
    }

    private func generateBabbleLayers() {
        layers = (0..<layerCount).map { _ in
            var noise = generateSpeechlikeNoise(length: segmentLength)
            DSPUtilities.bandpassFilter(
                &noise,
                lowFreq: lowFreq,
                highFreq: highFreq,
                sampleRate: 48000
            )

            // Apply pitch variation by resampling
            let pitchFactor = Float.random(in: 0.92...1.08)
            noise = resample(noise, factor: pitchFactor)

            // Normalize
            var peak: Float = 0
            vDSP_maxmgv(noise, 1, &peak, vDSP_Length(noise.count))
            if peak > 0 {
                var scale = 1.0 / peak
                vDSP_vsmul(noise, 1, &scale, &noise, 1, vDSP_Length(noise.count))
            }

            return noise
        }

        layerPositions = (0..<layerCount).map { _ in Int.random(in: 0..<segmentLength) }
        layerGains = (0..<layerCount).map { _ in Float.random(in: 0.6...1.0) }
    }

    private func generateSpeechlikeNoise(length: Int) -> [Float] {
        // Generate noise with speech-like spectral tilt (-6dB/octave)
        var noise = DSPUtilities.generateWhiteNoise(count: length)

        // Apply spectral tilt via simple IIR filter: y[n] = x[n] + 0.97 * y[n-1]
        var prev: Float = 0
        for i in 0..<length {
            noise[i] = noise[i] + 0.97 * prev
            prev = noise[i]
        }

        // Apply amplitude modulation (syllable-like rhythm at 3-5 Hz)
        let modFreq = Float.random(in: 3...5)
        let modPhase = Float.random(in: 0...(2 * .pi))
        for i in 0..<length {
            let t = Float(i) / 48000.0
            let envelope = 0.5 + 0.5 * sinf(2 * .pi * modFreq * t + modPhase)
            noise[i] *= envelope
        }

        return noise
    }

    private func resample(_ input: [Float], factor: Float) -> [Float] {
        let outputCount = Int(Float(input.count) / factor)
        var output = [Float](repeating: 0, count: outputCount)

        for i in 0..<outputCount {
            let srcIndex = Float(i) * factor
            let idx = Int(srcIndex)
            let frac = srcIndex - Float(idx)

            if idx + 1 < input.count {
                output[i] = input[idx] * (1.0 - frac) + input[idx + 1] * frac
            } else if idx < input.count {
                output[i] = input[idx]
            }
        }

        return output
    }
}
