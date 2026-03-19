import Foundation

struct PerturbationConfig: Codable {
    var intensity: Float = 0.8 {
        didSet { intensity = intensity.clamped(to: 0...1) }
    }

    var frequencyRangeLow: Float = 300.0 {
        didSet {
            let clampedLow = frequencyRangeLow.clamped(to: 80...8_000)
            if frequencyRangeLow != clampedLow {
                frequencyRangeLow = clampedLow
                return
            }

            // Ensure low stays at least 200 Hz below high.
            let minHigh = frequencyRangeLow + 200
            if frequencyRangeHigh < minHigh {
                frequencyRangeHigh = min(8_000, minHigh)
            }
        }
    }

    var frequencyRangeHigh: Float = 4_000.0 {
        didSet {
            let clampedHigh = frequencyRangeHigh.clamped(to: 280...8_000)
            if frequencyRangeHigh != clampedHigh {
                frequencyRangeHigh = clampedHigh
                return
            }

            // Ensure high stays at least 200 Hz above low.
            let maxLow = frequencyRangeHigh - 200
            if frequencyRangeLow > maxLow {
                frequencyRangeLow = max(80, maxLow)
            }
        }
    }

    var maskingAggressiveness: Float = 0.7 {
        didSet { maskingAggressiveness = maskingAggressiveness.clamped(to: 0...1) }
    }

    var codecTarget: CodecTarget = .opus64k

    var tier1Enabled: Bool = true
    var tier2Enabled: Bool = true

    var enabledTechniques: Set<String> = [
        PerturbationTechnique.spectralNotch.rawValue,
        PerturbationTechnique.babbleNoise.rawValue,
        PerturbationTechnique.frequencySweep.rawValue,
        PerturbationTechnique.uapEnsemble.rawValue
    ]

    // MARK: - Derived

    /// True only if at least one tier has an enabled technique.
    var isEffective: Bool {
        (tier1Enabled && PerturbationTechnique.allCases
            .filter { $0.tier == .tier1 }
            .contains { isTechniqueEnabled($0) })
        ||
        (tier2Enabled && PerturbationTechnique.allCases
            .filter { $0.tier == .tier2 }
            .contains { isTechniqueEnabled($0) })
    }

    // MARK: - Technique management

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

// MARK: - Comparable+clamped helper (private)

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - CodecTarget

enum CodecTarget: String, CaseIterable, Identifiable, Codable {
    case opus32k  = "Opus 32k"
    case opus64k  = "Opus 64k"
    case opus128k = "Opus 128k"
    case aac64k   = "AAC 64k"
    case none     = "None"

    var id: String { rawValue }

    var bitrateHz: Int {
        switch self {
        case .opus32k:  32_000
        case .opus64k:  64_000
        case .opus128k: 128_000
        case .aac64k:   64_000
        case .none:     0
        }
    }
}
