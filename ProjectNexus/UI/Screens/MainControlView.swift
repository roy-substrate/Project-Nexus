import SwiftUI

struct MainControlView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let asrService: ASREffectivenessService
    let onToggleShield: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                shieldHero
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    tierRow
                    spectrumCard
                    intensityCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) { statusStrip }
    }

    // MARK: - ASR Effectiveness

    /// Color encoding for the ASR jam score — from the user's perspective:
    /// higher jam % = stronger protection = more saturated blue/green.
    private var asrEffectivenessColor: Color {
        let s = asrService.effectivenessScore
        if s < 0.33 { return Color(.tertiaryLabel) }
        if s < 0.66 { return .blue }
        return Color(hue: 0.36, saturation: 0.78, brightness: 0.82) // vibrant green
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
                    // Outer breathing ring — only when active
                    if state.isShieldActive {
                        Circle()
                            .stroke(Color.blue.opacity(0.08), lineWidth: 48)
                            .frame(width: 168, height: 168)
                            .scaleEffect(audioScale * 1.06)
                            .animation(.interpolatingSpring(stiffness: 60, damping: 10), value: audioScale)

                        Circle()
                            .stroke(Color.blue.opacity(0.13), lineWidth: 20)
                            .frame(width: 168, height: 168)
                            .scaleEffect(audioScale)
                            .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: audioScale)

                        // ASR effectiveness arc — fills clockwise as jam % rises.
                        // Track ring (background)
                        Circle()
                            .stroke(Color(.systemFill), lineWidth: 4)
                            .frame(width: 148, height: 148)

                        // Live fill arc
                        Circle()
                            .trim(from: 0, to: CGFloat(asrService.effectivenessScore))
                            .stroke(
                                asrEffectivenessColor,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 148, height: 148)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6), value: asrService.effectivenessScore)
                    }

                    // Core
                    Circle()
                        .fill(state.isShieldActive
                              ? Color.blue
                              : Color(.secondarySystemGroupedBackground))
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: state.isShieldActive
                                ? Color.blue.opacity(0.35)
                                : Color.black.opacity(0.06),
                            radius: state.isShieldActive ? 24 : 6,
                            x: 0, y: state.isShieldActive ? 8 : 2
                        )
                        .scaleEffect(audioScale)
                        .animation(.interpolatingSpring(stiffness: 180, damping: 18), value: audioScale)

                    // Icon
                    VStack(spacing: 4) {
                        Image(systemName: state.isShieldActive
                              ? "shield.checkered.fill" : "shield.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(state.isShieldActive
                                             ? .white : Color(.tertiaryLabel))
                            .symbolEffect(.bounce, value: state.isShieldActive)
                            .contentTransition(.symbolEffect(.replace))

                        if state.isShieldActive {
                            WaveformView(isActive: true,
                                         level: metricsService.currentMetrics.rmsLevel)
                                .frame(width: 60, height: 14)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .heavy), trigger: state.isShieldActive)
            .frame(height: 220)
            .animation(.spring(response: 0.4, dampingFraction: 0.78), value: state.isShieldActive)

            // ── Status label ─────────────────────────────────────────
            VStack(spacing: 6) {
                Text(state.isShieldActive ? "Protecting your voice" : "Tap to activate")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(state.isShieldActive ? .blue : .primary)

                if state.isShieldActive && state.activeTechniqueCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("\(state.activeTechniqueCount) technique\(state.activeTechniqueCount == 1 ? "" : "s") active")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else if !state.isShieldActive {
                    Text("Voice protection off")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                // ASR jam score badge — only shown when measuring and score is meaningful
                if state.isShieldActive && asrService.isMeasuring && asrService.effectivenessScore > 0.05 {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(asrEffectivenessColor)
                        Text("\(Int(asrService.effectivenessScore * 100))% AI jammed")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(asrEffectivenessColor)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(asrEffectivenessColor.opacity(0.1)))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: state.isShieldActive)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Tier Row

    private var tierRow: some View {
        HStack(spacing: 10) {
            tierPill(
                label: "Acoustic",
                sublabel: "Tier 1",
                icon: "waveform",
                color: Color(hue: 0.58, saturation: 0.80, brightness: 0.92),
                enabled: state.config.tier1Enabled
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                    state.config.tier1Enabled.toggle()
                }
            }

            tierPill(
                label: "Adversarial",
                sublabel: "Tier 2",
                icon: "brain",
                color: Color(hue: 0.73, saturation: 0.70, brightness: 0.88),
                enabled: state.config.tier2Enabled
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                    state.config.tier2Enabled.toggle()
                }
            }
        }
    }

    private func tierPill(
        label: String,
        sublabel: String,
        icon: String,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(enabled ? color : Color(.tertiaryLabel))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(enabled ? color.opacity(0.12) : Color(.systemFill)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(enabled ? .primary : .secondary)
                    Text(sublabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                Spacer()

                // Minimal on/off dot
                Circle()
                    .fill(enabled ? color : Color(.systemFill))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                enabled ? color.opacity(0.25) : Color(.separator).opacity(0.4),
                                lineWidth: enabled ? 1 : 0.5
                            )
                    }
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Spectrum card

    private var spectrumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Spectrum")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if state.isShieldActive {
                    Label("Live", systemImage: "circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.green)
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
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            LevelMeterView(
                level: metricsService.currentMetrics.rmsLevel,
                peak: metricsService.currentMetrics.peakLevel
            )

            if state.isShieldActive && !metricsService.rmsHistory.allSatisfy({ $0 == -60 }) {
                SparklineView(values: metricsService.rmsHistory, color: .blue.opacity(0.4))
                    .frame(height: 18)
                    .transition(.opacity)
            }

            HStack {
                Text("100 Hz").frame(maxWidth: .infinity, alignment: .leading)
                Text("1 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("4 kHz").frame(maxWidth: .infinity, alignment: .center)
                Text("20 kHz").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Color(.quaternaryLabel))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.45), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Intensity card

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Intensity")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(Int(state.config.intensity * 100))%")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
            }

            Slider(value: $state.config.intensity, in: 0...1, step: 0.01)
                .tint(.blue)

            Text("Higher values increase jamming effectiveness but may become faintly audible.")
                .font(.system(size: 12))
                .foregroundStyle(Color(.tertiaryLabel))
                .lineSpacing(3)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.45), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Status strip

    private var statusStrip: some View {
        HStack(spacing: 0) {
            statusCell(
                value: String(format: "%.0f ms", metricsService.currentMetrics.latencyMs),
                label: "Latency",
                accent: metricsService.currentMetrics.latencyMs < 30 ? .green : .orange
            )
            Divider().frame(height: 22)
            statusCell(
                value: String(format: "%.0f dB", metricsService.currentMetrics.rmsLevel),
                label: "Level",
                accent: .secondary
            )
            Divider().frame(height: 22)
            statusCell(
                value: state.audioMode == .speakerPlayback ? "Speaker" : "VoIP",
                label: "Route",
                accent: .secondary
            )
            if state.isShieldActive {
                Divider().frame(height: 22)
                statusCell(
                    value: "\(state.activeTechniqueCount)",
                    label: "Active",
                    accent: .blue
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
    }

    private func statusCell(value: String, label: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(.quaternaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trailing icon label style (for "Live" badge)

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.system(size: 7))
            configuration.title
        }
    }
}
