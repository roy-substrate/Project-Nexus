import SwiftUI
import AVFoundation
import StoreKit

@main
struct ProjectNexusApp: App {
    @AppStorage("nexus.onboarding.completed") private var onboardingCompleted = false
    @AppStorage("nexus.reviewRequested") private var reviewRequested = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    @State private var appState = AppState()
    @State private var metricsService = MetricsService()
    @State private var perturbationService: PerturbationService?
    @State private var asrService = ASREffectivenessService()
    @State private var analyticsService = AnalyticsService()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                ContentView(
                    state: appState,
                    metricsService: metricsService,
                    asrService: asrService,
                    analyticsService: analyticsService,
                    subscriptionManager: subscriptionManager,
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                // Persist the current analytics session on both inactive and background
                // transitions. The inactive check ensures session data is saved even when
                // the user force-quits, which skips the background phase entirely.
                analyticsService.endSession()
            }
        }
    }

    // MARK: - Service setup

    private func setupServices() {
        guard perturbationService == nil else { return }
        do {
            let service = try PerturbationService()
            metricsService.startMonitoring(perturbationService: service)
            // Route mic buffers → ASR service (eliminates second AVAudioEngine)
            service.onMicBuffer = { [weak asrService = asrService] buffer in
                asrService?.appendBuffer(buffer)
            }
            perturbationService = service
        } catch {
            appState.errorMessage = error.localizedDescription
            return
        }

        // Start ASR effectiveness measurement
        Task {
            let granted = await asrService.requestAuthorization()
            if granted {
                asrService.startMeasuring(shieldActiveProvider: { [weak appState = appState] in
                    appState?.isShieldActive ?? false
                })
            }
        }

        // Track ASR score updates to analytics (drives peakJamScore in Account tab).
        // Also trigger a one-time App Store review request when the user first sees
        // a high jam score (>70%) — maximum social proof moment.
        asrService.onEffectivenessUpdate = { [weak self] score in
            self?.analyticsService.track(.asrScoreRecorded(score: score))
            if score > 0.70 && !(self?.reviewRequested ?? true) {
                self?.reviewRequested = true
                self?.requestReview()
            }
        }

        // Re-apply config whenever the audio route changes (e.g. headphones plug in/out).
        // Without this the perturbation output may route to the wrong port mid-session.
        NotificationCenter.default.addObserver(
            forName: .audioRouteChanged,
            object: nil,
            queue: .main
        ) { [weak perturbationService, weak appState = appState] _ in
            guard appState?.isShieldActive == true else { return }
            perturbationService?.updateConfig(appState?.config ?? PerturbationConfig())
        }
    }

    // MARK: - Shield toggle

    private var shieldActivationTime: Date? = nil

    private func toggleShield() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            appState.isShieldActive.toggle()
        }

        if appState.isShieldActive {
            do {
                try perturbationService?.start(with: appState.config)
                shieldActivationTime = Date()
                analyticsService.track(.shieldActivated)
            } catch {
                appState.isShieldActive = false
                appState.errorMessage = error.localizedDescription
            }
        } else {
            if let t = shieldActivationTime {
                let duration = Date().timeIntervalSince(t)
                analyticsService.track(.shieldDeactivated(durationSeconds: duration))
                shieldActivationTime = nil
            }
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
    let asrService: ASREffectivenessService
    let analyticsService: AnalyticsService
    let subscriptionManager: SubscriptionManager
    let onToggleShield: () -> Void
    let onConfigUpdate: () -> Void

    var body: some View {
        TabView(selection: $state.selectedTab) {
            Tab("Shield", systemImage: "shield.checkered.fill", value: AppTab.shield) {
                MainControlView(
                    state: state,
                    metricsService: metricsService,
                    asrService: asrService,
                    analyticsService: analyticsService,
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
                    isActive: state.isShieldActive,
                    asrService: asrService
                )
            }
            Tab("Account", systemImage: "person.circle", value: AppTab.account) {
                AccountView(analyticsService: analyticsService, subscriptionManager: subscriptionManager)
            }
        }
        .tint(NexusColor.accent)
        // Propagate all config mutations to the live service + persistence
        .onChange(of: state.config.intensity) { _, new in
            onConfigUpdate()
            analyticsService.track(.intensityChanged(value: new))
        }
        .onChange(of: state.config.tier1Enabled)            { _, _ in onConfigUpdate() }
        .onChange(of: state.config.tier2Enabled)            { _, _ in onConfigUpdate() }
        .onChange(of: state.config.enabledTechniques)       { _, _ in onConfigUpdate() }
        .onChange(of: state.config.maskingAggressiveness)   { _, _ in onConfigUpdate() }
        .onChange(of: state.config.codecTarget) { _, new in
            onConfigUpdate()
            analyticsService.track(.audioModeChanged(mode: new.rawValue))
        }
        .onChange(of: state.config.frequencyRangeLow)       { _, _ in onConfigUpdate() }
        .onChange(of: state.config.frequencyRangeHigh)      { _, _ in onConfigUpdate() }
    }
}
