import SwiftUI

struct MainControlView: View {
    @Bindable var state: AppState
    let metricsService: MetricsService
    let onToggleShield: () -> Void

    @Namespace private var tierNamespace
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Animated background
            backgroundLayer

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: NexusTheme.spacingLG) {
                    headerBar
                    shieldButton
                    tierCards
                    intensityControl
                    spectrumCard
                    statusBar
                }
                .padding(.horizontal, NexusTheme.spacingMD)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            NexusTheme.backgroundPrimary
                .ignoresSafeArea()

            // Mesh gradient background
            NexusTheme.backgroundGradient
                .ignoresSafeArea()
                .opacity(0.6)

            // Particle field
            ParticleFieldView(particleCount: 50, isActive: state.isShieldActive)
                .ignoresSafeArea()
                .opacity(0.8)

            // Radial glow when active
            if state.isShieldActive {
                RadialGradient(
                    colors: [
                        NexusTheme.accentCyan.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5), value: state.isShieldActive)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PROJECT")
                    .font(NexusTheme.captionFont)
                    .foregroundStyle(NexusTheme.textTertiary)
                    .tracking(3)

                Text("NEXUS")
                    .font(NexusTheme.displayFont)
                    .foregroundStyle(NexusTheme.textPrimary)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(NexusTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .glassCard(cornerRadius: 12, padding: 0)
            }
        }
        .padding(.top, NexusTheme.spacingSM)
    }

    // MARK: - Shield Button

    private var shieldButton: some View {
        Button(action: onToggleShield) {
            ZStack {
                // Pulse rings
                PulseRingView(isActive: state.isShieldActive, color: NexusTheme.accentCyan)
                    .frame(width: 200, height: 200)

                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle()
                            .fill(
                                state.isShieldActive
                                    ? NexusTheme.accentCyan.opacity(0.06)
                                    : NexusTheme.glassFill
                            )
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (state.isShieldActive ? NexusTheme.accentCyan : .white).opacity(0.25),
                                        NexusTheme.glassStroke,
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .frame(width: 160, height: 160)
                    .shadow(
                        color: state.isShieldActive ? NexusTheme.glowCyan : Color.clear,
                        radius: 30
                    )

                // Content inside circle
                VStack(spacing: NexusTheme.spacingSM) {
                    Image(systemName: state.isShieldActive ? "shield.checkered" : "shield")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            state.isShieldActive ? NexusTheme.accentCyan : NexusTheme.textSecondary
                        )
                        .symbolEffect(.bounce, value: state.isShieldActive)

                    Text(state.isShieldActive ? "SHIELDED" : "INACTIVE")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(
                            state.isShieldActive ? NexusTheme.accentCyan : NexusTheme.textTertiary
                        )
                        .tracking(2)

                    // Mini waveform
                    WaveformView(
                        isActive: state.isShieldActive,
                        level: metricsService.currentMetrics.rmsLevel
                    )
                    .frame(width: 80, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: state.isShieldActive)
        .padding(.vertical, NexusTheme.spacingSM)
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        HStack(spacing: NexusTheme.spacingSM) {
            TierCard(
                tier: .tier1,
                isEnabled: state.config.tier1Enabled
            ) {
                withAnimation(.bouncy) {
                    state.config.tier1Enabled.toggle()
                }
            }

            TierCard(
                tier: .tier2,
                isEnabled: state.config.tier2Enabled
            ) {
                withAnimation(.bouncy) {
                    state.config.tier2Enabled.toggle()
                }
            }
        }
    }

    // MARK: - Intensity

    private var intensityControl: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("Intensity")
                        .font(NexusTheme.bodyFont)
                        .foregroundStyle(NexusTheme.textPrimary)

                    Spacer()

                    Text("\(Int(state.config.intensity * 100))%")
                        .font(NexusTheme.monoFont)
                        .foregroundStyle(NexusTheme.accentCyan)
                }

                Slider(value: $state.config.intensity, in: 0...1, step: 0.05)
                    .tint(NexusTheme.accentCyan)
            }
        }
    }

    // MARK: - Spectrum

    private var spectrumCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("Spectrum")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                        .tracking(1)

                    Spacer()

                    if state.isShieldActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(NexusTheme.accentGreen)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(NexusTheme.monoSmall)
                                .foregroundStyle(NexusTheme.accentGreen)
                        }
                    }
                }

                SpectrumVisualizerView(
                    spectrumData: metricsService.currentMetrics.spectrumData,
                    maskingThreshold: metricsService.currentMetrics.maskingThreshold,
                    perturbationSpectrum: metricsService.currentMetrics.perturbationSpectrum,
                    isActive: state.isShieldActive
                )
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: NexusTheme.radiusSM))

                LevelMeterView(
                    level: metricsService.currentMetrics.rmsLevel,
                    peak: metricsService.currentMetrics.peakLevel
                )
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: NexusTheme.spacingLG) {
            statusItem(
                label: "Latency",
                value: String(format: "%.0fms", metricsService.currentMetrics.latencyMs),
                color: metricsService.currentMetrics.latencyMs < 30
                    ? NexusTheme.accentGreen
                    : NexusTheme.accentOrange
            )

            statusItem(
                label: "Level",
                value: String(format: "%.0fdB", metricsService.currentMetrics.rmsLevel),
                color: NexusTheme.textSecondary
            )

            statusItem(
                label: "Mode",
                value: state.audioMode.rawValue.components(separatedBy: " ").first ?? "",
                color: NexusTheme.accentCyan
            )

            if state.isShieldActive {
                statusItem(
                    label: "Active",
                    value: "\(state.activeTechniqueCount)",
                    color: NexusTheme.accentPurple
                )
            }
        }
        .font(NexusTheme.monoSmall)
    }

    private func statusItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(NexusTheme.textTertiary)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
        }
    }
}
