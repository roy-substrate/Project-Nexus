import SwiftUI

struct MainControlView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let asrService: ASREffectivenessService
    let analyticsService: AnalyticsService
    let subscriptionManager: SubscriptionManager
    let onToggleShield: () -> Void

    /// Captures peak jam score when shield deactivates for the post-session flash.
    @State private var sessionResultScore: Float = 0
    @State private var showSessionResult: Bool = false

    /// Tracks when the current shield session started for the live timer.
    @State private var sessionStartTime: Date?

    // MARK: - ASR permission nudge
    @AppStorage("nexus.asrPermissionNudgeShown") private var nudgeShown = false
    @State private var showASRNudge: Bool = false

    // MARK: - Paywall
    @State private var showPaywall: Bool = false

    // MARK: - Blinking cursor state
    @State private var cursorVisible: Bool = true
    private let cursorTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // ── Pure black background ─────────────────────────────────
            PixelColor.background
                .ignoresSafeArea()

            // ── Main content ──────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    shieldHero
                        .padding(.top, 8)

                    VStack(spacing: 14) {
                        tierRow
                        spectrumCard
                        intensityCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 36)
                }
            }
            .safeAreaInset(edge: .bottom) { statusStrip }
            .overlay(alignment: .top) { sessionResultBanner }
            .overlay(alignment: .bottom) { asrPermissionNudge }
        }
        .scanlines()
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
        .onChange(of: state.isShieldActive) { _, isActive in
            if isActive {
                sessionStartTime = .now
                if !asrService.isAuthorized && !nudgeShown {
                    withAnimation(PixelAnimation.appear) {
                        showASRNudge = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        withAnimation(PixelAnimation.dismiss) { showASRNudge = false }
                    }
                }
            } else {
                sessionStartTime = nil
                let score = asrService.effectivenessScore
                if score > 0.25 {
                    sessionResultScore = score
                    withAnimation(PixelAnimation.appear) {
                        showSessionResult = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(PixelAnimation.dismiss) { showSessionResult = false }
                    }
                }
            }
        }
        .onReceive(cursorTimer) { _ in
            cursorVisible.toggle()
        }
    }

    // MARK: - Session result banner

    @ViewBuilder
    private var sessionResultBanner: some View {
        if showSessionResult {
            HStack(spacing: 10) {
                Text("[OK]")
                    .font(PixelFont.terminal(12, weight: .bold))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
                Text("SESSION COMPLETE · \(Int(sessionResultScore * 100))% AI BLOCKED")
                    .font(PixelFont.terminal(12))
                    .foregroundStyle(PixelColor.text)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(PixelColor.background)
            .pixelBorder(PixelColor.phosphor)
            .padding(.top, 14)
            .padding(.horizontal, 18)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - ASR permission nudge

    @ViewBuilder
    private var asrPermissionNudge: some View {
        if showASRNudge {
            HStack(spacing: 12) {
                Text("[MIC]")
                    .font(PixelFont.terminal(11, weight: .bold))
                    .foregroundStyle(PixelColor.warning)

                Text("ENABLE SPEECH MEASUREMENT FOR JAM SCORE")
                    .font(PixelFont.terminal(11))
                    .foregroundStyle(PixelColor.text)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button("[ ON ]") {
                    Task { await asrService.requestAuthorization() }
                    nudgeShown = true
                    withAnimation(PixelAnimation.dismiss) { showASRNudge = false }
                }
                .font(PixelFont.terminal(11, weight: .bold))
                .foregroundStyle(PixelColor.phosphor)
                .phosphorGlow()

                Button("[ X ]") {
                    // Do not set nudgeShown — dismisses for this session only so the
                    // nudge can reappear on future sessions until the user grants access.
                    withAnimation(PixelAnimation.dismiss) { showASRNudge = false }
                }
                .font(PixelFont.terminal(11))
                .foregroundStyle(PixelColor.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(PixelColor.background)
            .pixelBorder()
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Protection history stat

    private var sessionCount: Int { analyticsService.sessionHistory.count }

    // MARK: - ASR Effectiveness

    private var asrEffectivenessColor: Color {
        let s = asrService.effectivenessScore
        if !state.isShieldActive || s < 0.05 { return PixelColor.textSecondary }
        return PixelColor.phosphor
    }

    // MARK: - Shield Hero

    private var audioScale: CGFloat {
        guard state.isShieldActive else { return 1.0 }
        let norm = CGFloat(max(0, (metricsService.currentMetrics.rmsLevel + 60) / 60))
        return 1.0 + norm * 0.05
    }

    private var shieldHero: some View {
        VStack(spacing: 0) {
            // ── Button ────────────────────────────────────────────────
            Button(action: onToggleShield) {
                ZStack {
                    // Shield box — 120×120 rectangle, square corners
                    if state.isShieldActive {
                        // Active: phosphor dither fill
                        DitherPatternView(
                            density: 0.15,
                            foreground: PixelColor.phosphor,
                            background: .black
                        )
                        .frame(width: 120, height: 120)
                        .pixelBorder(PixelColor.phosphor, width: 1)
                        .scaleEffect(audioScale)
                        .animation(PixelAnimation.audioPulse, value: audioScale)
                    } else {
                        // Inactive: pure black, white border
                        Rectangle()
                            .fill(PixelColor.background)
                            .frame(width: 120, height: 120)
                            .pixelBorder(PixelColor.border)
                    }

                    // ASCII shield label inside the box
                    VStack(spacing: 4) {
                        Text("[NEXUS]")
                            .font(PixelFont.hero(16))
                            .foregroundStyle(
                                state.isShieldActive ? PixelColor.phosphor : PixelColor.text
                            )
                            .if(state.isShieldActive) { $0.phosphorGlow() }

                        if state.isShieldActive {
                            WaveformView(isActive: true,
                                         level: metricsService.currentMetrics.rmsLevel)
                                .frame(width: 56, height: 12)
                                .transition(.opacity)
                        } else {
                            Text("/  \\")
                                .font(PixelFont.hero(10))
                                .foregroundStyle(PixelColor.textSecondary)
                            Text("| S |")
                                .font(PixelFont.hero(10))
                                .foregroundStyle(PixelColor.textSecondary)
                            Text(" \\_/")
                                .font(PixelFont.hero(10))
                                .foregroundStyle(PixelColor.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .heavy), trigger: state.isShieldActive)
            .frame(height: 136)
            .animation(PixelAnimation.primary, value: state.isShieldActive)

            // ── Status labels ─────────────────────────────────────────
            VStack(spacing: 6) {
                // Primary status line
                HStack(spacing: 0) {
                    Text("> ")
                        .font(PixelFont.terminal(14))
                        .foregroundStyle(PixelColor.textSecondary)
                    Text(state.isShieldActive ? "SHIELD ACTIVE" : "SHIELD OFFLINE")
                        .font(PixelFont.terminal(14, weight: .bold))
                        .foregroundStyle(
                            state.isShieldActive ? PixelColor.phosphor : PixelColor.textSecondary
                        )
                        .if(state.isShieldActive) { $0.phosphorGlow() }
                    // Blinking cursor when active
                    if state.isShieldActive {
                        Text(cursorVisible ? " ▌" : "  ")
                            .font(PixelFont.terminal(14))
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                    }
                }

                // Session timer — hero metric, monospaced
                if state.isShieldActive, let startTime = sessionStartTime {
                    VStack(spacing: 2) {
                        Text("UPTIME")
                            .font(PixelFont.stripLabel())
                            .foregroundStyle(PixelColor.textSecondary)
                            .kerning(1.5)
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text(sessionDurationString(since: startTime))
                                .font(PixelFont.hero(44))
                                .foregroundStyle(PixelColor.phosphor)
                                .phosphorGlow()
                                .contentTransition(.numericText())
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                if state.isShieldActive && state.activeTechniqueCount > 0 {
                    Text("TECH:\(state.activeTechniqueCount)  ACTIVE")
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if !state.isShieldActive {
                    Text("VOICE PROTECTION OFFLINE")
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.textSecondary)
                }

                if sessionCount > 0 && !state.isShieldActive {
                    Text("SESSIONS LOGGED: \(sessionCount)")
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.textSecondary)
                        .transition(.opacity)
                }

                // JAM score badge — pixel rectangle, text-art bar
                if state.isShieldActive && asrService.isMeasuring && asrService.effectivenessScore > 0.05 {
                    HStack(spacing: 8) {
                        Text("JAM:")
                            .font(PixelFont.terminal(12, weight: .bold))
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        PixelTextProgressBar(
                            value: asrService.effectivenessScore,
                            width: 8,
                            color: PixelColor.phosphor
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PixelColor.background)
                    .pixelBorder(PixelColor.phosphor)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeOut(duration: 0.15), value: state.isShieldActive)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Session timer helper

    private func sessionDurationString(since start: Date) -> String {
        let elapsed = Int(Date.now.timeIntervalSince(start))
        let seconds = elapsed % 60
        let minutes = (elapsed / 60) % 60
        let hours   = elapsed / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Tier Row

    private var tierRow: some View {
        HStack(spacing: 10) {
            tierToggle(
                label: "STD",
                sublabel: "TIER 1",
                color: state.config.tier1Enabled ? PixelColor.phosphor : PixelColor.border,
                enabled: state.config.tier1Enabled
            ) {
                withAnimation(PixelAnimation.primary) {
                    state.config.tier1Enabled.toggle()
                }
            }

            tierToggle(
                label: "AI",
                sublabel: "TIER 2",
                color: state.config.tier2Enabled ? PixelColor.phosphor : PixelColor.border,
                enabled: state.config.tier2Enabled
            ) {
                if subscriptionManager.isPro {
                    withAnimation(PixelAnimation.primary) {
                        state.config.tier2Enabled.toggle()
                    }
                } else {
                    showPaywall = true
                }
            }
        }
    }

    private func tierToggle(
        label: String,
        sublabel: String,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(PixelFont.terminal(14, weight: .bold))
                        .foregroundStyle(enabled ? PixelColor.phosphor : PixelColor.text)
                        .if(enabled) { $0.phosphorGlow() }
                    Text(enabled ? "●" : "○")
                        .font(PixelFont.terminal(12))
                        .foregroundStyle(enabled ? PixelColor.phosphor : PixelColor.textSecondary)
                        .if(enabled) { $0.phosphorGlow() }
                }
                Text(sublabel)
                    .font(PixelFont.stripLabel())
                    .kerning(1.5)
                    .foregroundStyle(PixelColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(PixelColor.background)
            .pixelBorder(enabled ? PixelColor.phosphor : PixelColor.border)
            .animation(PixelAnimation.primary, value: enabled)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Spectrum card

    private var spectrumCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SPECTRUM ANALYSIS")
                    .font(PixelFont.sectionHead())
                    .kerning(1.5)
                    .foregroundStyle(PixelColor.text)
                Spacer()
                if state.isShieldActive {
                    HStack(spacing: 4) {
                        Text("●")
                            .font(.system(size: 6, design: .monospaced))
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        Text("LIVE")
                            .font(PixelFont.sectionHead())
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                    }
                    .transition(.opacity)
                }
            }

            SpectrumVisualizerView(
                spectrumData: metricsService.currentMetrics.spectrumData,
                maskingThreshold: metricsService.currentMetrics.maskingThreshold,
                perturbationSpectrum: metricsService.currentMetrics.perturbationSpectrum,
                isActive: state.isShieldActive
            )
            .frame(height: 80)
            // Square corners — no clipShape roundedRectangle
            .pixelBorder()

            LevelMeterView(
                level: metricsService.currentMetrics.rmsLevel,
                peak: metricsService.currentMetrics.peakLevel
            )

            if state.isShieldActive && !metricsService.rmsHistory.allSatisfy({ $0 == -60 }) {
                SparklineView(
                    values: metricsService.rmsHistory,
                    color: PixelColor.phosphorDim
                )
                .frame(height: 18)
                .transition(.opacity)
            }

            HStack {
                Text("100HZ").frame(maxWidth: .infinity, alignment: .leading)
                Text("1KHZ").frame(maxWidth: .infinity, alignment: .center)
                Text("4KHZ").frame(maxWidth: .infinity, alignment: .center)
                Text("20KHZ").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(PixelFont.monoSmall(size: 9))
            .foregroundStyle(PixelColor.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(PixelColor.surface)
        .pixelBorder()
    }

    // MARK: - Intensity card

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("INTENSITY")
                    .font(PixelFont.sectionHead())
                    .kerning(1.5)
                    .foregroundStyle(PixelColor.text)
                Spacer()
                Text("\(Int(state.config.intensity * 100))%")
                    .font(PixelFont.terminal(15, weight: .bold))
                    .foregroundStyle(
                        state.isShieldActive ? PixelColor.phosphor : PixelColor.text
                    )
                    .if(state.isShieldActive) { $0.phosphorGlow() }
                    .contentTransition(.numericText())
            }

            // Text-art intensity bar
            PixelTextProgressBar(
                value: state.config.intensity,
                width: 12,
                color: state.isShieldActive ? PixelColor.phosphor : PixelColor.text
            )

            Slider(value: $state.config.intensity, in: 0...1, step: 0.01)
                .tint(state.isShieldActive ? PixelColor.phosphor : PixelColor.border)

            Text("HIGHER VALUES INCREASE JAM EFFECTIVENESS — MAY BECOME FAINTLY AUDIBLE.")
                .font(PixelFont.monoSmall(size: 10))
                .foregroundStyle(PixelColor.textSecondary)
                .lineSpacing(4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(PixelColor.surface)
        .pixelBorder()
    }

    // MARK: - Status strip

    private var statusStrip: some View {
        HStack(spacing: 0) {
            // Single-line terminal readout
            Text(statusLine)
                .font(PixelFont.stripLabel())
                .foregroundStyle(PixelColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(PixelColor.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PixelColor.border)
                .frame(height: 1)
        }
    }

    private var statusLine: String {
        let lat = String(format: "LAT:%.0fms", metricsService.currentMetrics.latencyMs)
        let lvl = String(format: "LVL:%.0fdB", metricsService.currentMetrics.rmsLevel)
        let route = state.audioMode == .speakerPlayback ? "ROUTE:SPK" : "ROUTE:VoIP"
        let tech = "TECH:\(state.activeTechniqueCount)"
        return "\(lat)  \(lvl)  \(route)  \(tech)"
    }
}

// MARK: - View.if helper

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
