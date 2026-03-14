import Foundation

enum PerturbationTier: String, CaseIterable, Identifiable, Codable {
    case tier1 = "Acoustic"
    case tier2 = "Adversarial"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .tier1: "Psychoacoustic noise injection targeting ASR feature extraction"
        case .tier2: "ML-generated universal adversarial perturbations"
        }
    }
}

enum PerturbationTechnique: String, CaseIterable, Identifiable, Codable {
    case spectralNotch = "Spectral Notch"
    case babbleNoise = "Babble Noise"
    case frequencySweep = "Frequency Sweep"
    case uapWhisper = "UAP Whisper"
    case uapDeepSpeech = "UAP DeepSpeech"
    case uapEnsemble = "UAP Ensemble"

    var id: String { rawValue }

    var tier: PerturbationTier {
        switch self {
        case .spectralNotch, .babbleNoise, .frequencySweep:
            return .tier1
        case .uapWhisper, .uapDeepSpeech, .uapEnsemble:
            return .tier2
        }
    }

    var iconName: String {
        switch self {
        case .spectralNotch: "waveform.path.ecg"
        case .babbleNoise: "person.3.fill"
        case .frequencySweep: "arrow.up.right"
        case .uapWhisper: "brain"
        case .uapDeepSpeech: "brain.head.profile"
        case .uapEnsemble: "cpu"
        }
    }
}
