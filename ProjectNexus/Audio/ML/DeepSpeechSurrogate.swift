import CoreML
import Accelerate
import os

final class DeepSpeechSurrogate: SurrogateModel {
    let name = "DeepSpeech2 Proxy"
    private(set) var isLoaded = false

    private let logger = Logger(subsystem: "com.nexus.ml", category: "DeepSpeech")

    private let sampleRate: Float = 16000
    private let nMFCC = 26
    private let frameSize = 512
    private let hopSize = 160

    func loadModel() async throws {
        // DeepSpeech2 uses MFCC features with CTC decoder
        // For scoring, we use MFCC distance as a proxy
        isLoaded = true
        logger.info("DeepSpeech proxy ready (MFCC-based scoring)")
    }

    func computeScore(for audioBuffer: [Float], withPerturbation perturbation: [Float]) -> Float {
        let cleanMFCC = computeMFCC(audioBuffer)

        var perturbed = audioBuffer
        for i in 0..<min(audioBuffer.count, perturbation.count) {
            perturbed[i] += perturbation[i]
        }
        let perturbedMFCC = computeMFCC(perturbed)

        guard cleanMFCC.count == perturbedMFCC.count, !cleanMFCC.isEmpty else { return 0 }

        var diff = [Float](repeating: 0, count: cleanMFCC.count)
        vDSP_vsub(cleanMFCC, 1, perturbedMFCC, 1, &diff, 1, vDSP_Length(cleanMFCC.count))

        var absSum: Float = 0
        vDSP_svemg(diff, 1, &absSum, vDSP_Length(diff.count))

        return absSum / Float(diff.count)
    }

    private func computeMFCC(_ audio: [Float]) -> [Float] {
        let frameCount = max(0, (audio.count - frameSize) / hopSize + 1)
        guard frameCount > 0 else { return [] }

        var mfccOutput = [Float](repeating: 0, count: frameCount * nMFCC)
        let window = DSPUtilities.generateHannWindow(size: frameSize)

        for frame in 0..<frameCount {
            let start = frame * hopSize
            let end = min(start + frameSize, audio.count)

            var windowed = [Float](repeating: 0, count: frameSize)
            for i in 0..<min(frameSize, end - start) {
                windowed[i] = audio[start + i] * window[i]
            }

            // Power spectrum
            let halfN = frameSize / 2
            var power = [Float](repeating: 0, count: halfN)
            for k in 0..<halfN {
                var real: Float = 0
                var imag: Float = 0
                for n in stride(from: 0, to: frameSize, by: 4) {
                    let angle = -2.0 * .pi * Float(k) * Float(n) / Float(frameSize)
                    real += windowed[n] * cosf(angle)
                    imag += windowed[n] * sinf(angle)
                }
                power[k] = real * real + imag * imag
            }

            // Mel filterbank (26 filters)
            var melEnergies = [Float](repeating: 0, count: nMFCC)
            for m in 0..<nMFCC {
                let lowMel = 0 + Float(m) * (2595.0 * log10(1.0 + sampleRate / 2 / 700.0)) / Float(nMFCC + 1)
                let centerMel = lowMel + (2595.0 * log10(1.0 + sampleRate / 2 / 700.0)) / Float(nMFCC + 1)

                let centerHz = 700.0 * (pow(10.0, centerMel / 2595.0) - 1.0)
                let centerBin = Int(centerHz * Float(frameSize) / sampleRate)

                var energy: Float = 0
                let bandwidth = max(1, halfN / nMFCC)
                for b in max(0, centerBin - bandwidth)...min(halfN - 1, centerBin + bandwidth) {
                    energy += power[b]
                }
                melEnergies[m] = log(max(energy, 1e-10))
            }

            // DCT to get MFCC (simplified)
            for c in 0..<nMFCC {
                var sum: Float = 0
                for m in 0..<nMFCC {
                    sum += melEnergies[m] * cosf(.pi * Float(c) * (Float(m) + 0.5) / Float(nMFCC))
                }
                mfccOutput[frame * nMFCC + c] = sum
            }
        }

        return mfccOutput
    }
}
