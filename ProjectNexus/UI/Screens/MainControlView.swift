import SwiftUI

struct MainControlView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let asrService: ASREffectivenessService
    let analyticsService: AnalyticsService
    let onToggleShield: () -> Void

    /// Captures peak jam score when shield deactivates for the post-session flash.
    @State private var sessionResultScore: Float = 0
    @State private var showSessionResult: Bool = false

    /// Tracks when the current shield session started for the live timer.
    @State private var sessionStartTime: Date?

    // MARK: - ASR permission nudge
    @AppStorage("nexus.asrPermissionNudgeShown") private var nudgeShown = false
    @State private var showASRNudge: Bool = false

    var body: some View {
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
        .background(NexusColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { statusStrip }
        .overlay(alignment: .top) { sessionResultBanner }
        .overlay(alignment: .bottom) { asrPermissionNudge }
        .onChange(of: state.isShieldActive) { _, isActive in
            if isActive {
                sessionStartTime = .now
                // Show ASR nudge once if mic permission was skipped during onboarding
                if !asrService.isAuthorized && !nudgeShown {
                    withAnimation(NexusAnimation.appear) {
                        showASRNudge = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        withAnimation(NexusAnimation.dismiss) { showASRNudge = false }
                    }
                }
            } else {
                sessionStartTime = nil
                let score = asrService.effectivenessScore
                if score > 0.5 {
                    sessionResultScore = score
                    withAnimation(NexusAnimation.appear) {
                        showSessionResult = true
                    }
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(NexusAnimation.dismiss) { showSessionResult = false }
                    }
                }
            }
        }
    }

    // MARK: - Session result banner (post-shield flash)

    @ViewBuilder
    private var sessionResultBanner: some View {
        if showSessionResult {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NexusColor.accentEmerald)
                Text("Session complete · \(Int(sessionResultScore * 100))% AI blocked")
                    .font(NexusFont.label())
                    .foregroundStyle(NexusColor.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(NexusColor.surfaceHigh)
                    .overlay {
                        Capsule()
                            .strokeBorder(NexusColor.accentEmerald.opacity(0.25), lineWidth: 1)
                    }
            }
            .padding(.top, 14)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - ASR permission nudge banner (one-time, non-blocking)

    @ViewBuilder
    private var asrPermissionNudge: some View {
        if showASRNudge {
            HStack(spacing: 12) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NexusColor.warning)

                Text("Enable speech measurement to see your jam score")
                    .font(NexusFont.label())
                    .foregroundStyle(NexusColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button("Enable") {
                    Task { await asrService.requestAuthorization() }
                    nudgeShown = true
                    withAnimation(NexusAnimation.dismiss) { showASRNudge = false }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NexusColor.accent)

                Button("Not now") {
                    nudgeShown = true
                    withAnimation(NexusAnimation.dismiss) { showASRNudge = false }
                }
                .font(.system(size: 13))
                .foregroundStyle(NexusColor.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NexusColor.surfaceHigh)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(NexusColor.cardBorder, lineWidth: 1)
                    }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Protection history stat

    /// Number of sessions protected, shown beneath the jam badge when > 0.
    private var sessionCount: Int { analyticsService.sessionHistory.count }

    // MARK: - ASR Effectiveness

    /// Color encoding for the ASR jam score — higher jam % = more protected = emerald.
    private var asrEffectivenessColor: Color {
        let s = asrService.effectivenessScore
        if s < 0.33 { return NexusColor.textTertiary }
        if s < 0.66 { return NexusColor.accent }
        return NexusColor.accentEmerald
    }

    // MARK: - Shield Hero

    /// RMS drives a subtle scale pulse — 0 dB = +5 % scale.
    private var audioScale: CGFloat {
        guard state.isShieldActive else { return 1.0 }
        let norm = CGFloat(max(0, (metricsService.currentMetrics.rmsLevel + 60) / 60))
        return 1.0 + norm * 0.05
    }

    private var shieldHero: some View {
        VStack(spacing: 0) {
            // ── Button ──────────────────────────────────────────────
            Button(action: onToggleShield) {
                ZStack {
                    // Outermost ambient glow — only when active
                    if state.isShieldActive {
                        Circle()
                            .fill(NexusColor.accentEmerald.opacity(0.04))
                            .frame(width: 220, height: 220)
                            .scaleEffect(audioScale * 1.08)
                            .animation(NexusAnimation.audioPulse, value: audioScale)

                        // Mid breathing ring
                        Circle()
                            .stroke(NexusColor.accentEmerald.opacity(0.10), lineWidth: 28)
                            .frame(width: 175, height: 175)
                            .scaleEffect(audioScale * 1.04)
                            .animation(.interpolatingSpring(stiffness: 55, damping: 12), value: audioScale)

                        // Inner breathing ring
                        Circle()
                            .stroke(NexusColor.accentEmerald.opacity(0.16), lineWidth: 12)
                            .frame(width: 155, height: 155)
                            .scaleEffect(audioScale)
                            .animation(.interpolatingSpring(stiffness: 100, damping: 14), value: audioScale)

                        // ASR effectiveness arc — track ring (background)
                        Circle()
                            .stroke(NexusColor.textTertiary.opacity(0.4), lineWidth: 3)
                            .frame(width: 148, height: 148)

                        // Live fill arc — instrument gauge aesthetic
                        Circle()
                            .trim(from: 0, to: CGFloat(asrService.effectivenessScore))
                            .stroke(
                                asrEffectivenessColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 148, height: 148)
                            .rotationEffect(.degrees(-90))
                            .animation(NexusAnimation.arcFill, value: asrService.effectivenessScore)
                    }

                    // Core circle — recessed when inactive, glowing when active
                    Circle()
                        .fill(
                            state.isShieldActive
                                ? NexusColor.accentEmerald.opacity(0.18)
                                : NexusColor.surface
                        )
                        .frame(width: 120, height: 120)
                        .overlay {
                            // Inner border — defines the physical edge
                            Circle()
                                .strokeBorder(
                                    state.isShieldActive
                                        ? NexusColor.accentEmerald.opacity(0.45)
                                        : NexusColor.textTertiary.opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: state.isShieldActive
                                ? NexusColor.accentEmerald.opacity(0.30)
                                : Color.clear,
                            radius: 28,
                            x: 0, y: 0
                        )
                        .scaleEffect(audioScale)
                        .animation(NexusAnimation.audioPulse, value: audioScale)

                    // Icon
                    VStack(spacing: 5) {
                        Image(systemName: state.isShieldActive
                              ? "shield.checkered.fill" : "shield.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(
                                state.isShieldActive
                                    ? NexusColor.accentEmerald
                                    : NexusColor.textTertiary
                            )
                            .symbolEffect(.bounce, value: state.isShieldActive)
                            .contentTransition(.symbolEffect(.replace))

                        if state.isShieldActive {
                            WaveformView(isActive: true,
                                         level: metricsService.currentMetrics.rmsLevel)
                                .frame(width: 56, height: 12)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .heavy), trigger: state.isShieldActive)
            .frame(height: 226)
            .animation(NexusAnimation.primary, value: state.isShieldActive)

            // ── Status labels ─────────────────────────────────────────
            VStack(spacing: 8) {
                Text(state.isShieldActive ? "Protecting your voice" : "Tap to activate")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .kerning(-0.3)
                    .foregroundStyle(
                        state.isShieldActive ? NexusColor.accentEmerald : NexusColor.textSecondary
                    )

                // Session timer — hero metric, SF Rounded for warmth
                if state.isShieldActive, let startTime = sessionStartTime {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(sessionDurationString(since: startTime))
                            .font(NexusFont.heroNumber(size: 44))
                            .foregroundStyle(NexusColor.textPrimary)
                            .contentTransition(.numericText())
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                if state.isShieldActive && state.activeTechniqueCount > 0 {
                    HStack(spacing: 6) {
                        // Precision status dot
                        Circle()
                            .fill(NexusColor.accentEmerald)
                            .frame(width: 5, height: 5)
                        Text("\(state.activeTechniqueCount) technique\(state.activeTechniqueCount == 1 ? "" : "s") active")
                            .font(NexusFont.caption())
                            .foregroundStyle(NexusColor.textSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if !state.isShieldActive {
                    Text("Voice protection off")
                        .font(NexusFont.caption())
                        .foregroundStyle(NexusColor.textTertiary)
                }

                // Protection history — shown when user has prior sessions
                if sessionCount > 0 && !state.isShieldActive {
                    HStack(spacing: 5) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(NexusColor.textTertiary)
                        Text("Protected \(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                            .font(NexusFont.caption())
                            .foregroundStyle(NexusColor.textTertiary)
                    }
                    .transition(.opacity)
                }

                // ASR jam score badge — only shown when measuring and score is meaningful
                if state.isShieldActive && asrService.isMeasuring && asrService.effectivenessScore > 0.05 {
                    HStack(spacing: 5) {
                        Image(systemName: "brain")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(asrEffectivenessColor)
                        Text("\(Int(asrService.effectivenessScore * 100))% AI jammed")
                            .font(NexusFont.mono(size: 12))
                            .foregroundStyle(asrEffectivenessColor)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(asrEffectivenessColor.opacity(0.10))
                            .overlay {
                                Capsule()
                                    .strokeBorder(asrEffectivenessColor.opacity(0.25), lineWidth: 1)
                            }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeOut(duration: 0.2), value: state.isShieldActive)
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
        HStack(spacing: 12) {
            tierToggle(
                label: "Standard",
                sublabel: "TIER 1",
                icon: "waveform",
                color: NexusColor.tier1,
                enabled: state.config.tier1Enabled
            ) {
                withAnimation(NexusAnimation.primary) {
                    state.config.tier1Enabled.toggle()
                }
            }

            tierToggle(
                label: "Advanced AI",
                sublabel: "TIER 2",
                icon: "brain",
                color: NexusColor.tier2,
                enabled: state.config.tier2Enabled
            ) {
                withAnimation(NexusAnimation.primary) {
                    state.config.tier2Enabled.toggle()
                }
            }
        }
    }

    /// Hardware toggle pill — the entire component changes state, not just a dot.
    private func tierToggle(
        label: String,
        sublabel: String,
        icon: String,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(enabled ? color.opacity(0.18) : NexusColor.surfaceHigh)
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(enabled ? color : NexusColor.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(NexusFont.label())
                        .foregroundStyle(enabled ? NexusColor.textPrimary : NexusColor.textSecondary)
                    Text(sublabel)
                        .font(NexusFont.sublabel())
                        .kerning(0.4)
                        .foregroundStyle(NexusColor.textTertiary)
                }

                Spacer()

                // Hardware-style status indicator — pill shape, not dot
                Capsule()
                    .fill(enabled ? color : NexusColor.textTertiary.opacity(0.3))
                    .frame(width: 26, height: 14)
                    .overlay(alignment: enabled ? .trailing : .leading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .padding(.horizontal, 2)
                            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                    }
                    .animation(NexusAnimation.primary, value: enabled)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(enabled ? color.opacity(0.07) : NexusColor.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                enabled ? color.opacity(0.28) : NexusColor.cardBorder,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Spectrum card

    private var spectrumCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Spectrum")
                    .font(NexusFont.sectionHead())
                    .kerning(-0.3)
                    .foregroundStyle(NexusColor.textPrimary)
                Spacer()
                if state.isShieldActive {
                    Label("Live", systemImage: "circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NexusColor.accentEmerald)
                        .labelStyle(TrailingIconLabelStyle())
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
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            LevelMeterView(
                level: metricsService.currentMetrics.rmsLevel,
                peak: metricsService.currentMetrics.peakLevel
            )

            if state.isShieldActive && !metricsService.rmsHistory.allSatisfy({ $0 == -60 }) {
                SparklineView(values: metricsService.rmsHistory, color: NexusColor.accent.opacity(0.45))
                    .frame(height: 18)
                    .transition(.opacity)
            }

            HStack {
                Text("100 Hz").frame(maxWidth: .infinity, alignment: .leading)
                Text("1 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("4 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("20 kHz").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(NexusFont.monoSmall())
            .foregroundStyle(NexusColor.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NexusColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NexusColor.cardBorder, lineWidth: 1)
                }
        }
    }

    // MARK: - Intensity card

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Intensity")
                    .font(NexusFont.sectionHead())
                    .kerning(-0.3)
                    .foregroundStyle(NexusColor.textPrimary)
                Spacer()
                Text("\(Int(state.config.intensity * 100))%")
                    .font(NexusFont.mono(size: 15))
                    .foregroundStyle(NexusColor.accent)
                    .contentTransition(.numericText())
            }

            Slider(value: $state.config.intensity, in: 0...1, step: 0.01)
                .tint(NexusColor.accent)

            Text("Higher values increase jamming effectiveness but may become faintly audible.")
                .font(NexusFont.caption())
                .foregroundStyle(NexusColor.textSecondary)
                .lineSpacing(4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NexusColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NexusColor.cardBorder, lineWidth: 1)
                }
        }
    }

    // MARK: - Status strip (precision instrument readout)

    private var statusStrip: some View {
        HStack(spacing: 0) {
            statusCell(
                value: String(format: "%.0f", metricsService.currentMetrics.latencyMs),
                unit: "ms",
                label: "LATENCY",
                accent: metricsService.currentMetrics.latencyMs < 30
                    ? NexusColor.accentEmerald
                    : NexusColor.warning
            )
            stripDivider
            statusCell(
                value: String(format: "%.0f", metricsService.currentMetrics.rmsLevel),
                unit: "dB",
                label: "LEVEL",
                accent: NexusColor.textSecondary
            )
            stripDivider
            statusCell(
                value: state.audioMode == .speakerPlayback ? "SPKR" : "VoIP",
                unit: nil,
                label: "ROUTE",
                accent: NexusColor.textSecondary
            )
            if state.isShieldActive {
                stripDivider
                statusCell(
                    value: "\(state.activeTechniqueCount)",
                    unit: nil,
                    label: "ACTIVE",
                    accent: NexusColor.accent
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(NexusColor.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NexusColor.stripBorder)
                .frame(height: 0.5)
        }
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(NexusColor.separator)
            .frame(width: 0.5, height: 18)
    }

    private func statusCell(value: String, unit: String?, label: String, accent: Color) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(NexusFont.mono(size: 13))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(NexusFont.mono(size: 9))
                        .foregroundStyle(accent.opacity(0.7))
                }
            }
            Text(label)
                .font(NexusFont.stripLabel())
                .kerning(0.5)
                .foregroundStyle(NexusColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trailing icon label style (for "Live" badge)

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 6))
            configuration.title
        }
    }
}
