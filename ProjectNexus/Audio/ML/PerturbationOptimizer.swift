import Foundation
import Accelerate
import os

final class PerturbationOptimizer {
    private let logger = Logger(subsystem: "com.nexus.ml", category: "Optimizer")

    private let parameterDim = 64
    private let sampleRate: Float = 48000
    private let epsilon: Float = 0.01

    private var currentParams: [Float]
    private var bestParams: [Float]
    private var bestScore: Float = 0

    private var stepSize: Float = 0.001
    private var iteration: Int = 0
    private let maxIterations = 100

    private let optimizationQueue = DispatchQueue(label: "com.nexus.optimizer", qos: .utility)

    var isOptimizing = false

    init() {
        currentParams = (0..<64).map { _ in Float.random(in: -0.5...0.5) }
        bestParams = currentParams
    }

    func startOptimization(
        ensemble: SurrogateEnsemble,
        referenceAudio: [Float],
        completion: @escaping ([Float]) -> Void
    ) {
        guard !isOptimizing else { return }
        isOptimizing = true
        iteration = 0

        optimizationQueue.async { [weak self] in
            guard let self else { return }

            while self.iteration < self.maxIterations && self.isOptimizing {
                let perturbation = self.paramsToWaveform(self.currentParams)
                let score = ensemble.evaluatePerturbation(
                    audioBuffer: referenceAudio,
                    perturbation: perturbation
                )

                if score > self.bestScore {
                    self.bestScore = score
                    self.bestParams = self.currentParams
                }

                // Random search step: perturb each parameter
                var candidate = self.currentParams
                for i in 0..<self.parameterDim {
                    candidate[i] += Float.random(in: -self.stepSize...self.stepSize)
                    candidate[i] = max(-1, min(1, candidate[i]))
                }

                let candidatePerturbation = self.paramsToWaveform(candidate)
                let candidateScore = ensemble.evaluatePerturbation(
                    audioBuffer: referenceAudio,
                    perturbation: candidatePerturbation
                )

                if candidateScore > score {
                    self.currentParams = candidate
                }

                self.iteration += 1

                if self.iteration % 10 == 0 {
                    self.logger.debug("Optimization iteration \(self.iteration), best score: \(self.bestScore)")
                }
            }

            let optimizedPerturbation = self.paramsToWaveform(self.bestParams)
            self.isOptimizing = false

            DispatchQueue.main.async {
                completion(optimizedPerturbation)
            }
        }
    }

    func stopOptimization() {
        isOptimizing = false
    }

    func paramsToWaveform(_ params: [Float]) -> [Float] {
        // Convert parameter vector to audio waveform
        // params[0..<32] = frequency band amplitudes
        // params[32..<64] = frequency band phases
        let count = Int(sampleRate)  // 1 second
        var waveform = [Float](repeating: 0, count: count)

        let halfDim = parameterDim / 2
        let frequencies: [Float] = (0..<halfDim).map { i in
            300 + Float(i) * (4000 - 300) / Float(halfDim)
        }

        for i in 0..<halfDim {
            let amplitude = params[i] * epsilon
            let phase = params[halfDim + i] * .pi

            for t in 0..<count {
                let time = Float(t) / sampleRate
                waveform[t] += amplitude * sinf(2 * .pi * frequencies[i] * time + phase)
            }
        }

        // Normalize to epsilon bound
        var peak: Float = 0
        vDSP_maxmgv(waveform, 1, &peak, vDSP_Length(count))
        if peak > epsilon {
            var scale = epsilon / peak
            vDSP_vsmul(waveform, 1, &scale, &waveform, 1, vDSP_Length(count))
        }

        return waveform
    }
}
