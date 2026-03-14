import Foundation
import os

protocol SurrogateModel {
    var name: String { get }
    var isLoaded: Bool { get }
    func loadModel() async throws
    func computeScore(for audioBuffer: [Float], withPerturbation perturbation: [Float]) -> Float
}

final class SurrogateEnsemble {
    private let logger = Logger(subsystem: "com.nexus.ml", category: "Ensemble")

    private var surrogates: [SurrogateModel] = []
    private let evaluationQueue = DispatchQueue(label: "com.nexus.ensemble", qos: .utility)

    var isReady: Bool {
        surrogates.allSatisfy(\.isLoaded)
    }

    func addSurrogate(_ model: SurrogateModel) {
        surrogates.append(model)
        logger.info("Added surrogate: \(model.name)")
    }

    func loadAll() async {
        for surrogate in surrogates {
            do {
                try await surrogate.loadModel()
                logger.info("Loaded surrogate: \(surrogate.name)")
            } catch {
                logger.error("Failed to load \(surrogate.name): \(error.localizedDescription)")
            }
        }
    }

    func evaluatePerturbation(
        audioBuffer: [Float],
        perturbation: [Float]
    ) -> Float {
        guard !surrogates.isEmpty else { return 0 }

        var totalScore: Float = 0
        let activeSurrogates = surrogates.filter(\.isLoaded)
        guard !activeSurrogates.isEmpty else { return 0 }

        for surrogate in activeSurrogates {
            let score = surrogate.computeScore(for: audioBuffer, withPerturbation: perturbation)
            totalScore += score
        }

        return totalScore / Float(activeSurrogates.count)
    }

    func evaluateAsync(
        audioBuffer: [Float],
        perturbation: [Float],
        completion: @escaping (Float) -> Void
    ) {
        evaluationQueue.async { [weak self] in
            guard let self else { return }
            let score = self.evaluatePerturbation(audioBuffer: audioBuffer, perturbation: perturbation)
            DispatchQueue.main.async {
                completion(score)
            }
        }
    }
}
