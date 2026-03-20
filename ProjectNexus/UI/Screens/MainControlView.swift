import SwiftUI

// MARK: - BlobMascot

/// Friendly rounded blob character — drawn with SwiftUI Canvas.
/// Closed-eyes crescent arcs convey calm focus (Headspace-style mascot).
private struct BlobMascot: View {
    let isActive: Bool
    let audioScale: CGFloat

    private var fillColor: Color {
        isActive ? PixelColor.phosphor : Color(red: 0.88, green: 0.86, blue: 0.84)
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let cx = w / 2, cy = h / 2

            // ── Blob body ──────────────────────────────────────────────
            // Rounded rectangle, slightly shorter on the bottom (organic feel).
            let blobPath = Path(
                roundedRect: CGRect(x: cx - w * 0.44, y: cy - h * 0.42,
                                    width: w * 0.88, height: h * 0.80),
                cornerRadius: min(w, h) * 0.38,
                style: .continuous
            )
            context.fill(blobPath, with: .color(fillColor))

            // ── Eyes (closed crescent arcs) ────────────────────────────
            let eyeColor: Color = isActive ? .white.opacity(0.92) : Color(red: 0.55, green: 0.53, blue: 0.51)
            let eyeY = cy - h * 0.04
            let eyeSpread: CGFloat = w * 0.16
            let eyeW: CGFloat = w * 0.14
            let eyeH: CGFloat = h * 0.06

            for sign: CGFloat in [-1, 1] {
                // Each eye is a downward crescent arc (bottom half of ellipse, flipped)
                var eyePath = Path()
                let ex = cx + sign * eyeSpread
                eyePath.move(to: CGPoint(x: ex - eyeW, y: eyeY))
                eyePath.addCurve(
                    to: CGPoint(x: ex + eyeW, y: eyeY),
                    control1: CGPoint(x: ex - eyeW * 0.5, y: eyeY + eyeH * 2.2),
                    control2: CGPoint(x: ex + eyeW * 0.5, y: eyeY + eyeH * 2.2)
                )
                context.stroke(
                    eyePath,
                    with: .color(eyeColor),
                    style: StrokeStyle(lineWidth: h * 0.038, lineCap: .round)
                )
            }
        }
        .scaleEffect(isActive ? audioScale : 1.0)
        .animation(PixelAnimation.audioPulse, value: audioScale)
    }
}

// MARK: - MainControlView

@available(iOS 17, *)
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

    // MARK: - Blinking cursor state (repurposed as status pulse)
    @State private var cursorVisible: Bool = true
    private let cursorTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // ── Warm background ────────────────────────────────────────
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
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PixelColor.phosphor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session complete")
                        .font(PixelFont.terminal(14, weight: .semibold))
                        .foregroundStyle(PixelColor.text)
                    Text("\(Int(sessionResultScore * 100))% of AI blocked")
                        .font(PixelFont.terminal(12))
                        .foregroundStyle(PixelColor.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(PixelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
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
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(PixelColor.warning)

                Text("Enable speech measurement for jam score")
                    .font(PixelFont.terminal(13))
                    .foregroundStyle(PixelColor.text)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button("Enable") {
                    Task { await asrService.requestAuthorization() }
                    nudgeShown = true
                    withAnimation(PixelAnimation.dismiss) { showASRNudge = false }
                }
                .font(PixelFont.terminal(13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(PixelColor.background)
                .clipShape(Capsule())

                Button {
                    withAnimation(PixelAnimation.dismiss) { showASRNudge = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PixelColor.textSecondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(PixelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Protection history stat

    private var sessionCount: Int { analyticsService.sessionHistory.count }

    // MARK: - Audio scale

    private var audioScale: CGFloat {
        guard state.isShieldActive else { return 1.0 }
        let norm = CGFloat(max(0, (metricsService.currentMetrics.rmsLevel + 60) / 60))
        return 1.0 + norm * 0.04
    }

    // MARK: - Shield Hero

    private var shieldHero: some View {
        VStack(spacing: 0) {

            // ── Hero blob button ───────────────────────────────────────
            Button(action: onToggleShield) {
                ZStack {
                    // Glow ring when active
                    if state.isShieldActive {
                        Circle()
                            .fill(PixelColor.phosphor.opacity(0.12))
                            .frame(width: 192, height: 192)
                            .scaleEffect(audioScale * 1.05)
                            .animation(PixelAnimation.audioPulse, value: audioScale)

                        Circle()
                            .fill(PixelColor.phosphor.opacity(0.07))
                            .frame(width: 220, height: 220)
                    }

                    // Blob mascot
                    BlobMascot(isActive: state.isShieldActive, audioScale: audioScale)
                        .frame(width: 160, height: 140)
                }
                .frame(height: 200)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .heavy), trigger: state.isShieldActive)
            .animation(PixelAnimation.primary, value: state.isShieldActive)
            .accessibilityLabel(state.isShieldActive ? "Deactivate shield" : "Activate shield")

            // ── Status labels ─────────────────────────────────────────
            VStack(spacing: 8) {

                // Status pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.isShieldActive ? PixelColor.phosphor : PixelColor.textSecondary)
                        .frame(width: 8, height: 8)
                        .opacity(cursorVisible || !state.isShieldActive ? 1 : 0.3)

                    Text(state.isShieldActive ? "Shield active" : "Shield offline")
                        .font(PixelFont.terminal(15, weight: .semibold))
                        .foregroundStyle(
                            state.isShieldActive ? PixelColor.text : PixelColor.textSecondary
                        )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(
                    state.isShieldActive
                        ? PixelColor.phosphor.opacity(0.10)
                        : PixelColor.border.opacity(0.50)
                )
                .clipShape(Capsule())

                // Session timer — shown when active
                if state.isShieldActive, let startTime = sessionStartTime {
                    VStack(spacing: 2) {
                        Text("Session time")
                            .font(PixelFont.stripLabel())
                            .foregroundStyle(PixelColor.textSecondary)
                            .kerning(0.5)
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text(sessionDurationString(since: startTime))
                                .font(PixelFont.hero(48))
                                .foregroundStyle(PixelColor.phosphor)
                                .contentTransition(.numericText())
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                // Subtitle — technique count or offline prompt
                Group {
                    if state.isShieldActive && state.activeTechniqueCount > 0 {
                        Text("\(state.activeTechniqueCount) technique\(state.activeTechniqueCount == 1 ? "" : "s") active")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if !state.isShieldActive {
                        Text("Tap the blob to start protecting your voice")
                    }
                }
                .font(PixelFont.terminal(13))
                .foregroundStyle(PixelColor.textSecondary)
                .multilineTextAlignment(.center)

                // Session count badge
                if sessionCount > 0 && !state.isShieldActive {
                    Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s") logged")
                        .font(PixelFont.terminal(12))
                        .foregroundStyle(PixelColor.textSecondary)
                        .transition(.opacity)
                }

                // JAM score pill
                if state.isShieldActive && asrService.isMeasuring && asrService.effectivenessScore > 0.05 {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.badge.minus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(PixelColor.phosphor)
                        Text("Jam score  \(Int(asrService.effectivenessScore * 100))%")
                            .font(PixelFont.terminal(13, weight: .semibold))
                            .foregroundStyle(PixelColor.phosphor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(PixelColor.phosphor.opacity(0.10))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(PixelAnimation.primary, value: state.isShieldActive)
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
                label: "Acoustic",
                sublabel: "Tier 1",
                icon: "waveform",
                color: NexusColor.tier1,
                enabled: state.config.tier1Enabled
            ) {
                withAnimation(PixelAnimation.primary) {
                    state.config.tier1Enabled.toggle()
                }
            }

            tierToggle(
                label: "Adversarial",
                sublabel: "Tier 2",
                icon: "brain",
                color: NexusColor.tier2,
                enabled: state.config.tier2Enabled
            ) {
                withAnimation(PixelAnimation.primary) {
                    state.config.tier2Enabled.toggle()
                }
            }
        }
    }

    private func tierToggle(
        label: String,
        sublabel: String,
        icon: String,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(enabled ? color : PixelColor.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(enabled ? color.opacity(0.12) : PixelColor.border.opacity(0.50))
                    )

                VStack(spacing: 3) {
                    Text(label)
                        .font(PixelFont.terminal(13, weight: .semibold))
                        .foregroundStyle(enabled ? PixelColor.text : PixelColor.textSecondary)
                    Text(sublabel)
                        .font(PixelFont.stripLabel())
                        .foregroundStyle(PixelColor.textSecondary)
                }

                // Mini toggle pill
                Capsule()
                    .fill(enabled ? color : PixelColor.border)
                    .frame(width: 36, height: 18)
                    .overlay(alignment: enabled ? .trailing : .leading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .padding(.horizontal, 2)
                            .shadow(color: Color.black.opacity(0.15), radius: 2)
                    }
                    .animation(PixelAnimation.primary, value: enabled)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(PixelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: (enabled ? color : Color.black).opacity(enabled ? 0.14 : 0.05),
                radius: 10, x: 0, y: 4
            )
            .animation(PixelAnimation.primary, value: enabled)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Spectrum card

    private var spectrumCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spectrum Analysis")
                        .font(PixelFont.terminal(15, weight: .semibold))
                        .foregroundStyle(PixelColor.text)
                    Text("Live frequency monitoring")
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.textSecondary)
                }
                Spacer()
                if state.isShieldActive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(PixelColor.phosphor)
                            .frame(width: 7, height: 7)
                        Text("Live")
                            .font(PixelFont.terminal(12, weight: .semibold))
                            .foregroundStyle(PixelColor.phosphor)
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
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            LevelMeterView(
                level: metricsService.currentMetrics.rmsLevel,
                peak: metricsService.currentMetrics.peakLevel
            )

            if state.isShieldActive && !metricsService.rmsHistory.allSatisfy({ $0 == -60 }) {
                SparklineView(
                    values: metricsService.rmsHistory,
                    color: PixelColor.phosphor.opacity(0.55)
                )
                .frame(height: 20)
                .transition(.opacity)
            }

            HStack {
                Text("100 Hz").frame(maxWidth: .infinity, alignment: .leading)
                Text("1 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("4 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("20 kHz").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(PixelFont.monoSmall(size: 10))
            .foregroundStyle(PixelColor.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(PixelColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Intensity card

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intensity")
                        .font(PixelFont.terminal(15, weight: .semibold))
                        .foregroundStyle(PixelColor.text)
                    Text("Perturbation strength")
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.textSecondary)
                }
                Spacer()
                Text("\(Int(state.config.intensity * 100))%")
                    .font(PixelFont.hero(22))
                    .foregroundStyle(
                        state.isShieldActive ? PixelColor.phosphor : PixelColor.text
                    )
                    .contentTransition(.numericText())
            }

            // Smooth progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(PixelColor.border.opacity(0.60))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [PixelColor.warning, PixelColor.phosphor],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(state.config.intensity),
                            height: 10
                        )
                        .animation(PixelAnimation.arcFill, value: state.config.intensity)
                }
            }
            .frame(height: 10)

            Slider(value: $state.config.intensity, in: 0...1, step: 0.01)
                .tint(state.isShieldActive ? PixelColor.phosphor : PixelColor.border)

            Text("Higher values increase jam effectiveness — may become faintly audible.")
                .font(PixelFont.monoSmall(size: 11))
                .foregroundStyle(PixelColor.textSecondary)
                .lineSpacing(3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(PixelColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Status strip

    private var statusStrip: some View {
        HStack(spacing: 16) {
            statusChip(label: statusLatency, icon: "timer")
            statusChip(label: statusLevel, icon: "waveform")
            statusChip(label: statusRoute, icon: "speaker.wave.2")
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(PixelColor.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PixelColor.border)
                .frame(height: 0.5)
        }
    }

    private func statusChip(label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(PixelColor.textSecondary)
            Text(label)
                .font(PixelFont.stripLabel())
                .foregroundStyle(PixelColor.textSecondary)
        }
    }

    private var statusLatency: String {
        String(format: "%.0f ms", metricsService.currentMetrics.latencyMs)
    }
    private var statusLevel: String {
        String(format: "%.0f dB", metricsService.currentMetrics.rmsLevel)
    }
    private var statusRoute: String {
        state.audioMode == .speakerPlayback ? "Speaker" : "VoIP"
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
