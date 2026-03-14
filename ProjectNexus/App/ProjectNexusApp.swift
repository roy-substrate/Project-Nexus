import SwiftUI
import AVFoundation

@main
struct ProjectNexusApp: App {
    @AppStorage("nexus.onboarding.completed") private var onboardingCompleted = false

    @State private var appState = AppState()
    @State private var metricsService = MetricsService()
    @State private var perturbationService: PerturbationService?

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                ContentView(
                    state: appState,
                    metricsService: metricsService,
                    onToggleShield: toggleShield,
                    onConfigUpdate: applyConfigUpdate
                )
                .onAppear { setupServices() }
                .alert("Shield Unavailable", isPresented: Binding(
                    get: { appState.errorMessage != nil },
                    set: { if !$0 { appState.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { appState.errorMessage = nil }
                } message: {
                    Text(appState.errorMessage ?? "")
                }
            } else {
                OnboardingView()
            }
        }
    }

    // MARK: - Service setup

    private func setupServices() {
        guard perturbationService == nil else { return }
        let service = PerturbationService()
        metricsService.startMonitoring(perturbationService: service)
        perturbationService = service
    }

    // MARK: - Shield toggle

    private func toggleShield() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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

    // MARK: - Live config updates

    /// Saves the config and pushes any changes to the active service.
    private func applyConfigUpdate() {
        appState.saveConfig()
        if appState.isShieldActive {
            perturbationService?.updateConfig(appState.config)
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let onToggleShield: () -> Void
    let onConfigUpdate: () -> Void

    var body: some View {
        TabView(selection: $state.selectedTab) {
            Tab("Shield", systemImage: "shield.checkered.fill", value: AppTab.shield) {
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
                DiagnosticsView(metricsService: metricsService, isActive: state.isShieldActive)
            }
        }
        .tint(.blue)
        // Propagate all config mutations to the live service + persistence
        .onChange(of: state.config.intensity)               { _, _ in onConfigUpdate() }
        .onChange(of: state.config.tier1Enabled)            { _, _ in onConfigUpdate() }
        .onChange(of: state.config.tier2Enabled)            { _, _ in onConfigUpdate() }
        .onChange(of: state.config.enabledTechniques)       { _, _ in onConfigUpdate() }
        .onChange(of: state.config.maskingAggressiveness)   { _, _ in onConfigUpdate() }
        .onChange(of: state.config.codecTarget)             { _, _ in onConfigUpdate() }
        .onChange(of: state.config.frequencyRangeLow)       { _, _ in onConfigUpdate() }
        .onChange(of: state.config.frequencyRangeHigh)      { _, _ in onConfigUpdate() }
    }
}
