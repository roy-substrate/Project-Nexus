import SwiftUI

private let configDefaultsKey = "perturbationConfig"

@Observable
final class AppState {
    var isShieldActive: Bool = false
    var config: PerturbationConfig = AppState.loadConfig()
    var audioMode: AudioMode = .speakerPlayback
    var metrics: AudioMetrics = .empty
    var selectedTab: AppTab = .shield

    /// Non-nil when the shield failed to start; drives an alert in the root view.
    var errorMessage: String? = nil

    var tier1Active: Bool {
        isShieldActive && config.tier1Enabled
    }

    var tier2Active: Bool {
        isShieldActive && config.tier2Enabled
    }

    var activeTechniqueCount: Int {
        guard isShieldActive else { return 0 }
        return PerturbationTechnique.allCases.filter { technique in
            let tierEnabled = technique.tier == .tier1 ? config.tier1Enabled : config.tier2Enabled
            return tierEnabled && config.isTechniqueEnabled(technique)
        }.count
    }

    // MARK: - Persistence

    func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: configDefaultsKey)
    }

    private static func loadConfig() -> PerturbationConfig {
        guard
            let data = UserDefaults.standard.data(forKey: configDefaultsKey),
            let saved = try? JSONDecoder().decode(PerturbationConfig.self, from: data)
        else { return PerturbationConfig() }
        return saved
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case shield = "Shield"
    case settings = "Settings"
    case routing = "Routing"
    case diagnostics = "Diagnostics"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .shield: "shield.checkered"
        case .settings: "slider.horizontal.3"
        case .routing: "antenna.radiowaves.left.and.right"
        case .diagnostics: "chart.bar.xaxis"
        }
    }
}
