import SwiftUI

struct PerturbationSettingsView: View {
    @Bindable var state: AppState

    var body: some View {
        ZStack {
            NexusTheme.backgroundPrimary.ignoresSafeArea()
            NexusTheme.backgroundGradient.ignoresSafeArea().opacity(0.4)
            ParticleFieldView(particleCount: 25, isActive: false).ignoresSafeArea().opacity(0.4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: NexusTheme.spacingLG) {
                    sectionHeader("Tier 1 — Acoustic", color: NexusTheme.accentCyan)
                    tier1Section

                    sectionHeader("Tier 2 — Adversarial", color: NexusTheme.accentPurple)
                    tier2Section

                    sectionHeader("Frequency Range", color: NexusTheme.textSecondary)
                    frequencyRangeSection

                    sectionHeader("Codec Target", color: NexusTheme.textSecondary)
                    codecSection

                    sectionHeader("Advanced", color: NexusTheme.textSecondary)
                    advancedSection
                }
                .padding(.horizontal, NexusTheme.spacingMD)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Text(title.uppercased())
                .font(NexusTheme.captionFont)
                .foregroundStyle(color)
                .tracking(1.5)
            Spacer()
        }
        .padding(.top, NexusTheme.spacingSM)
    }

    // MARK: - Tier 1

    private var tier1Section: some View {
        VStack(spacing: NexusTheme.spacingSM) {
            techniqueToggle(.spectralNotch, tint: NexusTheme.accentCyan)
            techniqueToggle(.babbleNoise, tint: NexusTheme.accentCyan)
            techniqueToggle(.frequencySweep, tint: NexusTheme.accentCyan)
        }
    }

    // MARK: - Tier 2

    private var tier2Section: some View {
        VStack(spacing: NexusTheme.spacingSM) {
            techniqueToggle(.uapWhisper, tint: NexusTheme.accentPurple)
            techniqueToggle(.uapDeepSpeech, tint: NexusTheme.accentPurple)
            techniqueToggle(.uapEnsemble, tint: NexusTheme.accentPurple)
        }
    }

    // MARK: - Frequency Range

    private var frequencyRangeSection: some View {
        GlassCard {
            VStack(spacing: NexusTheme.spacingMD) {
                HStack {
                    Text("\(Int(state.config.frequencyRangeLow)) Hz")
                        .font(NexusTheme.monoFont)
                        .foregroundStyle(NexusTheme.accentCyan)

                    Spacer()

                    Text("\(Int(state.config.frequencyRangeHigh)) Hz")
                        .font(NexusTheme.monoFont)
                        .foregroundStyle(NexusTheme.accentPurple)
                }

                // Low frequency slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Low Cutoff")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                    Slider(value: $state.config.frequencyRangeLow, in: 100...1000, step: 50)
                        .tint(NexusTheme.accentCyan)
                }

                // High frequency slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("High Cutoff")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                    Slider(value: $state.config.frequencyRangeHigh, in: 2000...8000, step: 100)
                        .tint(NexusTheme.accentPurple)
                }

                // Visual frequency band indicator
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let lowNorm = CGFloat((state.config.frequencyRangeLow - 100) / 7900)
                    let highNorm = CGFloat((state.config.frequencyRangeHigh - 100) / 7900)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(NexusTheme.glassFill)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(NexusTheme.spectrumGradient)
                            .frame(width: (highNorm - lowNorm) * totalWidth, height: 6)
                            .offset(x: lowNorm * totalWidth)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    // MARK: - Codec

    private var codecSection: some View {
        GlassCard {
            VStack(spacing: NexusTheme.spacingSM) {
                ForEach(CodecTarget.allCases) { target in
                    Button {
                        withAnimation(.bouncy) {
                            state.config.codecTarget = target
                        }
                    } label: {
                        HStack {
                            Text(target.rawValue)
                                .font(NexusTheme.bodyFont)
                                .foregroundStyle(
                                    state.config.codecTarget == target
                                        ? NexusTheme.textPrimary
                                        : NexusTheme.textTertiary
                                )

                            Spacer()

                            if state.config.codecTarget == target {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NexusTheme.accentCyan)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, NexusTheme.spacingXS)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        GlassCard {
            VStack(spacing: NexusTheme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Masking Aggressiveness")
                            .font(NexusTheme.bodyFont)
                            .foregroundStyle(NexusTheme.textPrimary)
                        Spacer()
                        Text("\(Int(state.config.maskingAggressiveness * 100))%")
                            .font(NexusTheme.monoFont)
                            .foregroundStyle(NexusTheme.accentOrange)
                    }
                    Text("How close to audibility threshold")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                    Slider(value: $state.config.maskingAggressiveness, in: 0...1, step: 0.05)
                        .tint(NexusTheme.accentOrange)
                }
            }
        }
    }

    // MARK: - Helpers

    private func techniqueToggle(_ technique: PerturbationTechnique, tint: Color) -> some View {
        let isEnabled = state.config.isTechniqueEnabled(technique)

        return Button {
            withAnimation(.bouncy) {
                state.config.toggleTechnique(technique)
            }
        } label: {
            GlassCard(tint: isEnabled ? tint : nil) {
                HStack(spacing: NexusTheme.spacingSM) {
                    Image(systemName: technique.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isEnabled ? tint : NexusTheme.textTertiary)
                        .frame(width: 28)

                    Text(technique.rawValue)
                        .font(NexusTheme.bodyFont)
                        .foregroundStyle(isEnabled ? NexusTheme.textPrimary : NexusTheme.textSecondary)

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isEnabled ? tint.opacity(0.3) : NexusTheme.glassFill)
                            .frame(width: 44, height: 26)

                        Circle()
                            .fill(isEnabled ? tint : NexusTheme.textTertiary)
                            .frame(width: 20, height: 20)
                            .offset(x: isEnabled ? 9 : -9)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
