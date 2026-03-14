import CoreML
import Accelerate
import os

final class WhisperSurrogate: SurrogateModel {
    let name = "Whisper-Tiny Encoder"
    private(set) var isLoaded = false

    private let logger = Logger(subsystem: "com.nexus.ml", category: "Whisper")
    private var model: MLModel?

    private let sampleRate: Float = 16000
    private let nMels = 80
    private let hopLength = 160
    private let nFFT = 400

    func loadModel() async throws {
        guard let modelURL = Bundle.main.url(forResource: "WhisperTinyEncoder", withExtension: "mlmodelc") else {
            logger.info("Whisper CoreML model not found in bundle, using spectral proxy")
            isLoaded = true
            return
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all
        model = try MLModel(contentsOf: modelURL, configuration: config)
        isLoaded = true
        logger.info("Whisper CoreML model loaded")
    }

    func computeScore(for audioBuffer: [Float], withPerturbation perturbation: [Float]) -> Float {
        // Compute mel spectrograms for clean and perturbed audio
        let cleanMel = computeMelSpectrogram(audioBuffer)
        var perturbed = audioBuffer
        for i in 0..<min(audioBuffer.count, perturbation.count) {
            perturbed[i] += perturbation[i]
        }
        let perturbedMel = computeMelSpectrogram(perturbed)

        // Score = mean absolute difference in mel space
        // Higher score = more distortion in ASR feature space
        guard cleanMel.count == perturbedMel.count, !cleanMel.isEmpty else { return 0 }

        var diff = [Float](repeating: 0, count: cleanMel.count)
        vDSP_vsub(cleanMel, 1, perturbedMel, 1, &diff, 1, vDSP_Length(cleanMel.count))

        var absSum: Float = 0
        vDSP_svemg(diff, 1, &absSum, vDSP_Length(diff.count))

        return absSum / Float(diff.count)
    }

    private func computeMelSpectrogram(_ audio: [Float]) -> [Float] {
        let frameCount = audio.count / hopLength
        guard frameCount > 0 else { return [] }

        var melSpec = [Float](repeating: 0, count: frameCount * nMels)
        let window = DSPUtilities.generateHannWindow(size: nFFT)

        for frame in 0..<frameCount {
            let start = frame * hopLength
            let end = min(start + nFFT, audio.count)
            let available = end - start

            var windowed = [Float](repeating: 0, count: nFFT)
            for i in 0..<available {
                windowed[i] = audio[start + i] * window[i]
            }

            // Simple DFT magnitude approximation
            let halfN = nFFT / 2
            var magnitudes = [Float](repeating: 0, count: halfN)
            for k in 0..<halfN {
                var real: Float = 0
                var imag: Float = 0
                for n in 0..<nFFT {
                    let angle = -2.0 * .pi * Float(k) * Float(n) / Float(nFFT)
                    real += windowed[n] * cosf(angle)
                    imag += windowed[n] * sinf(angle)
                }
                magnitudes[k] = sqrtf(real * real + imag * imag)
            }

            // Map to mel bands (simplified triangular filterbank)
            for mel in 0..<nMels {
                let centerFreq = melToHz(Float(mel) * hzToMel(8000) / Float(nMels))
                let centerBin = Int(centerFreq * Float(nFFT) / sampleRate)
                let bandwidth = max(1, Int(Float(nMels) * 0.5))

                var energy: Float = 0
                for b in max(0, centerBin - bandwidth)...min(halfN - 1, centerBin + bandwidth) {
                    let weight = 1.0 - Float(abs(b - centerBin)) / Float(bandwidth)
                    energy += magnitudes[b] * weight
                }

                melSpec[frame * nMels + mel] = log(max(energy, 1e-10))
            }
        }

        return melSpec
    }

    private func hzToMel(_ hz: Float) -> Float {
        2595.0 * log10(1.0 + hz / 700.0)
    }

    private func melToHz(_ mel: Float) -> Float {
        700.0 * (pow(10.0, mel / 2595.0) - 1.0)
    }
}
