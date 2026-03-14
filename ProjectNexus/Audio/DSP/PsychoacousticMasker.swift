import Accelerate
import Foundation

final class PsychoacousticMasker {
    private let fftSize: Int
    private let sampleRate: Float
    private let barkBandCount = 24

    private var maskingThreshold: [Float]
    private var spreadingMatrix: [[Float]]
    private var barkBandPower: [Float]

    private let lock = os_unfair_lock_t.allocate(capacity: 1)

    init(fftSize: Int = 1024, sampleRate: Float = 48000) {
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        self.maskingThreshold = [Float](repeating: -60, count: fftSize / 2)
        self.barkBandPower = [Float](repeating: 0, count: barkBandCount)
        self.spreadingMatrix = PsychoacousticMasker.buildSpreadingMatrix(bandCount: barkBandCount)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deallocate()
    }

    func computeThreshold(from spectrum: [Float]) {
        let halfN = fftSize / 2
        guard spectrum.count >= halfN else { return }

        // Map FFT bins to Bark bands
        for band in 0..<barkBandCount {
            let lowFreq = DSPUtilities.barkBandEdges[band]
            let highFreq = DSPUtilities.barkBandEdges[min(band + 1, DSPUtilities.barkBandEdges.count - 1)]
            let lowBin = DSPUtilities.frequencyToBin(lowFreq, sampleRate: sampleRate, fftSize: fftSize)
            let highBin = DSPUtilities.frequencyToBin(highFreq, sampleRate: sampleRate, fftSize: fftSize)

            var maxPower: Float = -100
            for bin in lowBin...min(highBin, halfN - 1) {
                maxPower = max(maxPower, spectrum[bin])
            }
            barkBandPower[band] = maxPower
        }

        // Apply spreading function
        var spreadPower = [Float](repeating: -100, count: barkBandCount)
        for i in 0..<barkBandCount {
            for j in 0..<barkBandCount {
                let spread = barkBandPower[j] + spreadingMatrix[j][i]
                if spread > spreadPower[i] {
                    spreadPower[i] = spread
                }
            }
        }

        // Compute masking threshold per bin
        var newThreshold = [Float](repeating: -60, count: halfN)
        for bin in 0..<halfN {
            let freq = DSPUtilities.binToFrequency(bin, sampleRate: sampleRate, fftSize: fftSize)
            let bark = DSPUtilities.frequencyToBark(freq)
            let bandIndex = min(barkBandCount - 1, max(0, Int(bark)))

            // Masking threshold is spread power minus offset (typically 6-12 dB below masker)
            let offset: Float = 8.0
            newThreshold[bin] = spreadPower[bandIndex] - offset

            // Apply absolute threshold of hearing
            let ath = absoluteThresholdOfHearing(freq)
            newThreshold[bin] = max(newThreshold[bin], ath)
        }

        os_unfair_lock_lock(lock)
        maskingThreshold = newThreshold
        os_unfair_lock_unlock(lock)
    }

    func getCurrentThreshold() -> [Float] {
        os_unfair_lock_lock(lock)
        let result = maskingThreshold
        os_unfair_lock_unlock(lock)
        return result
    }

    func getMaxAmplitude(forBin bin: Int) -> Float {
        os_unfair_lock_lock(lock)
        let thresholdDB = maskingThreshold[min(bin, maskingThreshold.count - 1)]
        os_unfair_lock_unlock(lock)
        return powf(10.0, thresholdDB / 20.0)
    }

    private func absoluteThresholdOfHearing(_ freq: Float) -> Float {
        guard freq > 0 else { return 100 }
        let f = freq / 1000.0
        return 3.64 * powf(f, -0.8)
            - 6.5 * expf(-0.6 * powf(f - 3.3, 2))
            + 1e-3 * powf(f, 4)
            - 60.0
    }

    private static func buildSpreadingMatrix(bandCount: Int) -> [[Float]] {
        var matrix = [[Float]](repeating: [Float](repeating: -100, count: bandCount), count: bandCount)
        for i in 0..<bandCount {
            for j in 0..<bandCount {
                let distance = Float(j - i)
                let spreading: Float
                if distance >= 0 {
                    // Upward spread: ~25 dB/Bark
                    spreading = -25.0 * distance
                } else {
                    // Downward spread: ~10 dB/Bark
                    spreading = 10.0 * distance
                }
                matrix[i][j] = max(spreading, -60)
            }
        }
        return matrix
    }
}
