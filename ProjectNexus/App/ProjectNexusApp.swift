import SwiftUI

@main
struct ProjectNexusApp: App {
    @State private var appState = AppState()
    @State private var metricsService = MetricsService()
    @State private var perturbationService: PerturbationService?

    var body: some Scene {
        WindowGroup {
            ContentView(
                state: appState,
                metricsService: metricsService,
                onToggleShield: toggleShield
            )
            .onAppear {
                setupServices()
            }
        }
    }

    private func setupServices() {
        let service = PerturbationService()
        metricsService.startMonitoring(perturbationService: service)
        perturbationService = service
    }

    private func toggleShield() {
        withAnimation(.bouncy(duration: 0.5)) {
            appState.isShieldActive.toggle()
        }

        if appState.isShieldActive {
            do {
                try perturbationService?.start(with: appState.config)
            } catch {
                appState.isShieldActive = false
            }
        } else {
            perturbationService?.stop()
        }
    }
}

struct ContentView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let onToggleShield: () -> Void

    var body: some View {
        TabView(selection: $state.selectedTab) {
            Tab("Shield", systemImage: "shield.checkered", value: .shield) {
                MainControlView(
                    state: state,
                    metricsService: metricsService,
                    onToggleShield: onToggleShield
                )
            }

            Tab("Settings", systemImage: "slider.horizontal.3", value: .settings) {
                PerturbationSettingsView(state: state)
            }

            Tab("Routing", systemImage: "antenna.radiowaves.left.and.right", value: .routing) {
                AudioRoutingView(state: state)
            }

            Tab("Diagnostics", systemImage: "chart.bar.xaxis", value: .diagnostics) {
                DiagnosticsView(
                    metricsService: metricsService,
                    isActive: state.isShieldActive
                )
            }
        }
        .tint(NexusTheme.accentCyan)
        .preferredColorScheme(.dark)
        .onChange(of: state.config.intensity) { _, _ in
            updateConfig()
        }
        .onChange(of: state.config.tier1Enabled) { _, _ in
            updateConfig()
        }
        .onChange(of: state.config.tier2Enabled) { _, _ in
            updateConfig()
        }
    }

    private func updateConfig() {
        // Will be handled by perturbation service through app state observation
    }
}
