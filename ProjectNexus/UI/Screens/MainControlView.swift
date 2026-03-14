import SwiftUI

struct MainControlView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let onToggleShield: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                shieldHero
                    .padding(.top, 12)
                tierGrid
                intensityCard
                spectrumCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) { statusStrip }
    }

    // MARK: - Shield hero

    /// Audio-reactive RMS level mapped to a subtle scale pulse (0 dB → +5% scale).
    private var audioScale: CGFloat {
        guard state.isShieldActive else { return 1.0 }
        let rms = metricsService.currentMetrics.rmsLevel
        let normalised = CGFloat(max(0, (rms + 60) / 60))   // 0 at silence, 1 at 0 dBFS
        return 1.0 + normalised * 0.055
    }

    private var shieldHero: some View {
        VStack(spacing: 20) {
            Button(action: onToggleShield) {
                ZStack {
                    // Outermost ambient ring — pulses gently when active
                    if state.isShieldActive {
                        Circle()
                            .stroke(Color.blue.opacity(0.10), lineWidth: 1)
                            .frame(width: 192, height: 192)
                            .scaleEffect(audioScale)
                            .animation(.interpolatingSpring(stiffness: 120, damping: 14), value: audioScale)

                        Circle()
                            .stroke(Color.blue.opacity(0.06), lineWidth: 1)
                            .frame(width: 220, height: 220)
                            .scaleEffect(audioScale * 1.03)
                            .animation(.interpolatingSpring(stiffness: 80, damping: 12), value: audioScale)
                    }

                    // Core button
                    Circle()
                        .fill(state.isShieldActive ? Color.blue : Color(.secondarySystemGroupedBackground))
                        .frame(width: 140, height: 140)
                        .shadow(
                            color: state.isShieldActive ? Color.blue.opacity(0.30) : .black.opacity(0.07),
                            radius: state.isShieldActive ? 18 : 5,
                            x: 0, y: state.isShieldActive ? 6 : 2
                        )
                        .scaleEffect(audioScale)
                        .animation(.interpolatingSpring(stiffness: 200, damping: 18), value: audioScale)

                    // Icon + state label inside button
                    VStack(spacing: 5) {
                        Image(systemName: state.isShieldActive
                              ? "shield.checkered.fill"
                              : "shield.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(state.isShieldActive ? .white : Color(.tertiaryLabel))
                            .symbolEffect(.bounce, value: state.isShieldActive)
                            .contentTransition(.symbolEffect(.replace))

                        Text(state.isShieldActive ? "Active" : "Off")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                state.isShieldActive ? .white.opacity(0.80) : Color(.tertiaryLabel)
                            )

                        // Live waveform inside button when active
                        if state.isShieldActive {
                            WaveformView(
                                isActive: true,
                                level: metricsService.currentMetrics.rmsLevel
                            )
                            .frame(width: 72, height: 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .heavy), trigger: state.isShieldActive)
            .frame(height: 240)

            // Caption beneath button
            VStack(spacing: 4) {
                Text(state.isShieldActive
                     ? "Protecting your voice"
                     : "Tap to start protecting")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(state.isShieldActive ? .blue : .secondary)

                if state.isShieldActive && state.activeTechniqueCount > 0 {
                    Text("\(state.activeTechniqueCount) technique\(state.activeTechniqueCount == 1 ? "" : "s") running")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: state.isShieldActive)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Tier grid

    private var tierGrid: some View {
        HStack(spacing: 10) {
            TierCard(tier: .tier1, isEnabled: state.config.tier1Enabled) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    state.config.tier1Enabled.toggle()
                }
            }
            TierCard(tier: .tier2, isEnabled: state.config.tier2Enabled) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    state.config.tier2Enabled.toggle()
                }
            }
        }
    }

    // MARK: - Intensity card

    private var intensityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Intensity")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(state.config.intensity * 100))%")
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                }
                Slider(value: $state.config.intensity, in: 0...1, step: 0.01)
                    .tint(.blue)
                Text("Higher values are more effective but may become audible")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Spectrum card

    private var spectrumCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Spectrum")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if state.isShieldActive {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
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
                .frame(height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                LevelMeterView(
                    level: metricsService.currentMetrics.rmsLevel,
                    peak: metricsService.currentMetrics.peakLevel
                )

                // RMS sparkline — uses the history ring buffer from MetricsService
                if state.isShieldActive && !metricsService.rmsHistory.allSatisfy({ $0 == -60 }) {
                    SparklineView(
                        values: metricsService.rmsHistory,
                        color: .blue.opacity(0.45)
                    )
                    .frame(height: 20)
                    .transition(.opacity)
                }

                HStack {
                    Text("100 Hz"); Spacer()
                    Text("1 kHz"); Spacer()
                    Text("4 kHz"); Spacer()
                    Text("20 kHz")
                }
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.quaternary)
            }
        }
    }

    // MARK: - Status strip (safe area inset)

    private var statusStrip: some View {
        HStack(spacing: 0) {
            statusCell(
                value: String(format: "%.0f ms", metricsService.currentMetrics.latencyMs),
                label: "Latency",
                accent: metricsService.currentMetrics.latencyMs < 30 ? .green : .orange
            )
            Color(.separator).frame(width: 0.5, height: 22)
            statusCell(
                value: String(format: "%.0f dB", metricsService.currentMetrics.rmsLevel),
                label: "Level",
                accent: .secondary
            )
            Color(.separator).frame(width: 0.5, height: 22)
            statusCell(
                value: state.audioMode == .speakerPlayback ? "Speaker" : "VoIP",
                label: "Route",
                accent: .secondary
            )
            if state.isShieldActive {
                Color(.separator).frame(width: 0.5, height: 22)
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
            Color(.separator).frame(height: 0.5)
        }
    }

    private func statusCell(value: String, label: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity)
    }
}
