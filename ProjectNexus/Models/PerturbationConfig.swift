import Foundation

struct PerturbationConfig: Codable {
    var intensity: Float = 0.8
    var frequencyRangeLow: Float = 300.0
    var frequencyRangeHigh: Float = 4000.0
    var maskingAggressiveness: Float = 0.7
    var codecTarget: CodecTarget = .opus64k

    var tier1Enabled: Bool = true
    var tier2Enabled: Bool = true

    var enabledTechniques: Set<String> = [
        PerturbationTechnique.spectralNotch.rawValue,
        PerturbationTechnique.babbleNoise.rawValue,
        PerturbationTechnique.frequencySweep.rawValue,
        PerturbationTechnique.uapEnsemble.rawValue
    ]

    func isTechniqueEnabled(_ technique: PerturbationTechnique) -> Bool {
        enabledTechniques.contains(technique.rawValue)
    }

    mutating func toggleTechnique(_ technique: PerturbationTechnique) {
        if enabledTechniques.contains(technique.rawValue) {
            enabledTechniques.remove(technique.rawValue)
        } else {
            enabledTechniques.insert(technique.rawValue)
        }
    }
}

enum CodecTarget: String, CaseIterable, Identifiable, Codable {
    case opus32k = "Opus 32k"
    case opus64k = "Opus 64k"
    case opus128k = "Opus 128k"
    case aac64k = "AAC 64k"
    case none = "None"

    var id: String { rawValue }

    var bitrateHz: Int {
        switch self {
        case .opus32k: 32_000
        case .opus64k: 64_000
        case .opus128k: 128_000
        case .aac64k: 64_000
        case .none: 0
        }
    }
}
