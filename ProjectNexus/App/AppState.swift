import SwiftUI
import Combine

@Observable
final class AppState {
    var isShieldActive: Bool = false
    var config: PerturbationConfig = PerturbationConfig()
    var audioMode: AudioMode = .speakerPlayback
    var metrics: AudioMetrics = .empty
    var selectedTab: AppTab = .shield

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
