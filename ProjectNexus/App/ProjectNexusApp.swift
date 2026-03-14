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
                onToggleShield: toggleShield,
                onConfigUpdate: applyConfigUpdate
            )
            .onAppear {
                setupServices()
            }
            .alert("Shield Unavailable", isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { appState.errorMessage = nil }
            } message: {
                Text(appState.errorMessage ?? "")
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
                appState.errorMessage = error.localizedDescription
            }
        } else {
            perturbationService?.stop()
        }
    }

    /// Called whenever a config property changes while the shield may be active.
    private func applyConfigUpdate() {
        appState.saveConfig()
        if appState.isShieldActive {
            perturbationService?.updateConfig(appState.config)
        }
    }
}

struct ContentView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let onToggleShield: () -> Void
    let onConfigUpdate: () -> Void

    var body: some View {
        TabView(selection: $state.selectedTab) {
            Tab("Shield", systemImage: "shield.checkered", value: AppTab.shield) {
                MainControlView(
                    state: state,
                    metricsService: metricsService,
                    onToggleShield: onToggleShield
                )
            }

            Tab("Settings", systemImage: "slider.horizontal.3", value: AppTab.settings) {
                PerturbationSettingsView(state: state)
            }

            Tab("Routing", systemImage: "antenna.radiowaves.left.and.right", value: AppTab.routing) {
                AudioRoutingView(state: state)
            }

            Tab("Diagnostics", systemImage: "chart.bar.xaxis", value: AppTab.diagnostics) {
                DiagnosticsView(
                    metricsService: metricsService,
                    isActive: state.isShieldActive
                )
            }
        }
        .tint(NexusTheme.accentBlue)
        .preferredColorScheme(.light)
        .onChange(of: state.config.intensity)           { _, _ in onConfigUpdate() }
        .onChange(of: state.config.tier1Enabled)        { _, _ in onConfigUpdate() }
        .onChange(of: state.config.tier2Enabled)        { _, _ in onConfigUpdate() }
        .onChange(of: state.config.enabledTechniques)   { _, _ in onConfigUpdate() }
        .onChange(of: state.config.maskingAggressiveness) { _, _ in onConfigUpdate() }
        .onChange(of: state.config.codecTarget)         { _, _ in onConfigUpdate() }
        .onChange(of: state.config.frequencyRangeLow)   { _, _ in onConfigUpdate() }
        .onChange(of: state.config.frequencyRangeHigh)  { _, _ in onConfigUpdate() }
    }
}
