import Foundation

final class FrequencySweepGenerator: PerturbationGenerator {
    var isEnabled: Bool = true

    private let maxConcurrentSweeps = 4
    private var sweeps: [Sweep] = []
    private var intensity: Float = 0.8

    private let lowFreq: Float = 300
    private let highFreq: Float = 4000
    private let sampleRate: Float = 48000

    init(intensity: Float = 0.8) {
        self.intensity = intensity
        initializeSweeps()
    }

    func setIntensity(_ value: Float) {
        intensity = max(0, min(1, value))
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            var sample: Float = 0

            for j in 0..<sweeps.count {
                sample += sweeps[j].nextSample()

                if sweeps[j].isComplete {
                    sweeps[j] = Sweep.random(lowFreq: lowFreq, highFreq: highFreq, sampleRate: self.sampleRate)
                }
            }

            buffer[i] = sample * intensity * 0.1 / Float(maxConcurrentSweeps)
        }
    }

    func updateMaskingThreshold(_ threshold: [Float]) {
        // Could use threshold to modulate sweep amplitudes
    }

    private func initializeSweeps() {
        sweeps = (0..<maxConcurrentSweeps).map { _ in
            var sweep = Sweep.random(lowFreq: lowFreq, highFreq: highFreq, sampleRate: sampleRate)
            // Offset each sweep randomly into its duration
            let skipSamples = Int.random(in: 0..<sweep.totalSamples)
            for _ in 0..<skipSamples { _ = sweep.nextSample() }
            return sweep
        }
    }
}

private struct Sweep {
    let startFreq: Float
    let endFreq: Float
    let sampleRate: Float
    let totalSamples: Int
    let gain: Float

    private var phase: Float = 0
    private var sampleIndex: Int = 0

    var isComplete: Bool { sampleIndex >= totalSamples }

    mutating func nextSample() -> Float {
        guard !isComplete else { return 0 }

        let t = Float(sampleIndex) / Float(totalSamples)

        // Linear frequency interpolation
        let freq = startFreq + (endFreq - startFreq) * t

        // Phase accumulation for continuous frequency sweep
        phase += 2.0 * .pi * freq / sampleRate
        if phase > 2.0 * .pi { phase -= 2.0 * .pi }

        // Envelope: raised cosine fade in/out
        let envelope: Float
        let fadeLength: Float = 0.1
        if t < fadeLength {
            envelope = 0.5 - 0.5 * cosf(.pi * t / fadeLength)
        } else if t > 1.0 - fadeLength {
            envelope = 0.5 - 0.5 * cosf(.pi * (1.0 - t) / fadeLength)
        } else {
            envelope = 1.0
        }

        sampleIndex += 1
        return sinf(phase) * envelope * gain
    }

    static func random(lowFreq: Float, highFreq: Float, sampleRate: Float) -> Sweep {
        let ascending = Bool.random()
        let durationMs = Float.random(in: 50...200)
        let totalSamples = Int(durationMs * sampleRate / 1000.0)

        let f1 = Float.random(in: lowFreq...highFreq)
        let f2 = Float.random(in: lowFreq...highFreq)

        return Sweep(
            startFreq: ascending ? min(f1, f2) : max(f1, f2),
            endFreq: ascending ? max(f1, f2) : min(f1, f2),
            sampleRate: sampleRate,
            totalSamples: totalSamples,
            gain: Float.random(in: 0.5...1.0)
        )
    }
}
