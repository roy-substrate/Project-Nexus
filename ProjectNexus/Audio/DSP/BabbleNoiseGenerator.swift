import Foundation
import Accelerate
import Synchronization
import os

final class BabbleNoiseGenerator: PerturbationGenerator {
    private let _isEnabled = Atomic<Bool>(true)
    var isEnabled: Bool {
        get { _isEnabled.load(ordering: .relaxed) }
        set { _isEnabled.store(newValue, ordering: .relaxed) }
    }

    // Atomic backing so the CoreAudio render thread (read) and main thread (write via
    // setIntensity) never race on the intensity value.
    private let _intensity = Atomic<Float>(0.8)
    private var intensity: Float {
        get { _intensity.load(ordering: .relaxed) }
        set { _intensity.store(newValue, ordering: .relaxed) }
    }

    private let layerCount = 4
    private let segmentLength = 48000 * 3  // 3 seconds at 48kHz
    private var layers: [[Float]] = []
    private var layerPositions: [Int] = []
    private var layerGains: [Float] = []

    // Protects layers/layerPositions/layerGains: mutated on main thread in
    // generateBabbleLayers(), read on the CoreAudio render thread in fillBuffer().
    private let layersLock = os_unfair_lock_t.allocate(capacity: 1)

    private var lowFreq: Float
    private var highFreq: Float

    init(intensity: Float = 0.8, lowFreq: Float = 17_000, highFreq: Float = 20_000) {
        self.lowFreq = lowFreq
        self.highFreq = highFreq
        layersLock.initialize(to: os_unfair_lock())
        self.intensity = max(0, min(1, intensity))
        generateBabbleLayers()
    }

    deinit {
        layersLock.deallocate()
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

        let currentIntensity = intensity
        os_unfair_lock_lock(layersLock)
        let layersCopy = layers
        var positionsCopy = layerPositions
        let gainsCopy = layerGains
        os_unfair_lock_unlock(layersLock)

        for l in 0..<layerCount {
            guard l < layersCopy.count else { continue }
            let layer = layersCopy[l]
            let layerLen = layer.count
            var pos = positionsCopy[l]
            var gain = gainsCopy[l] * currentIntensity * 0.12

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
            positionsCopy[l] = pos
        }

        os_unfair_lock_lock(layersLock)
        layerPositions = positionsCopy
        os_unfair_lock_unlock(layersLock)
    }

    func updateMaskingThreshold(_ threshold: [Float]) {
        // Babble noise uses fixed spectrum, masking threshold could modulate gain
    }

    private func generateBabbleLayers() {
        var newLayers: [[Float]] = (0..<layerCount).map { _ in
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

        let newPositions = (0..<layerCount).map { _ in Int.random(in: 0..<segmentLength) }
        let newGains = (0..<layerCount).map { _ in Float.random(in: 0.6...1.0) }

        os_unfair_lock_lock(layersLock)
        layers = newLayers
        layerPositions = newPositions
        layerGains = newGains
        os_unfair_lock_unlock(layersLock)
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
