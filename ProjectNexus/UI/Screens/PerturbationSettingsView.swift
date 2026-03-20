import SwiftUI

struct PerturbationSettingsView: View {
    @Bindable var state: AppState

    var body: some View {
        NavigationStack {
            Form {
                acousticSection
                adversarialSection
                frequencySection
                codecSection
                advancedSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.visible)
        }
    }

    // MARK: - Tier 1 — Acoustic

    private var acousticSection: some View {
        Section {
            Toggle(isOn: $state.config.tier1Enabled) {
                Label("Acoustic Tier", systemImage: "waveform")
            }
            .tint(NexusTheme.tier1)

            if state.config.tier1Enabled {
                techniqueRow(.spectralNotch)
                techniqueRow(.babbleNoise)
                techniqueRow(.frequencySweep)
            }
        } header: {
            Text("Acoustic Shield")
        } footer: {
            Text("Psychoacoustic masking injects noise below your hearing threshold to disrupt ASR feature extraction.")
        }
    }

    // MARK: - Tier 2 — Adversarial ML

    private var adversarialSection: some View {
        Section {
            Toggle(isOn: $state.config.tier2Enabled) {
                Label("Adversarial Tier", systemImage: "brain")
            }
            .tint(NexusTheme.tier2)

            if state.config.tier2Enabled {
                techniqueRow(.uapWhisper)
                techniqueRow(.uapDeepSpeech)
                techniqueRow(.uapEnsemble)
            }
        } header: {
            Text("Adversarial ML")
        } footer: {
            Text("Universal adversarial perturbations (UAPs) are ML-crafted signals that cause specific ASR models to misrecognize speech.")
        }
    }

    // MARK: - Frequency range

    private var frequencySection: some View {
        Section {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("Low cutoff")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.textSecondary)
                    Spacer()
                    Text("\(Int(state.config.frequencyRangeLow)) Hz")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(NexusTheme.tier1)
                }
                Slider(value: $state.config.frequencyRangeLow,
                       in: 80...8_000,
                       step: 10)
                    .tint(NexusTheme.tier1)
                    .onChange(of: state.config.frequencyRangeLow) { _, newLow in
                        // Ensure low doesn't exceed high minus minimum gap
                        if newLow > state.config.frequencyRangeHigh - 200 {
                            state.config.frequencyRangeHigh = newLow + 200
                        }
                    }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("High cutoff")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.textSecondary)
                    Spacer()
                    Text("\(Int(state.config.frequencyRangeHigh)) Hz")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(NexusTheme.tier2)
                }
                Slider(value: $state.config.frequencyRangeHigh,
                       in: 280...8_000,
                       step: 10)
                    .tint(NexusTheme.tier2)
                    .onChange(of: state.config.frequencyRangeHigh) { _, newHigh in
                        // Ensure high doesn't go below low plus minimum gap
                        if newHigh < state.config.frequencyRangeLow + 200 {
                            state.config.frequencyRangeLow = newHigh - 200
                        }
                    }
            }
            .padding(.vertical, 4)

            // Visual band indicator
            frequencyBandBar
                .padding(.vertical, 6)

        } header: {
            Text("Frequency Range")
        } footer: {
            Text("Defines the speech-band frequency range where perturbations are generated. The default range (300–4000 Hz) targets ASR feature extraction.")
        }
    }

    private var frequencyBandBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let totalRange: Float = 8_000 - 80
            let lowNorm  = CGFloat((state.config.frequencyRangeLow  - 80) / totalRange)
            let highNorm = CGFloat((state.config.frequencyRangeHigh - 80) / totalRange)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemFill))
                    .frame(height: 5)

                Capsule()
                    .fill(NexusTheme.spectrumGradient)
                    .frame(width: max(4, (highNorm - lowNorm) * w), height: 5)
                    .offset(x: lowNorm * w)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Codec

    private var codecSection: some View {
        Section {
            Picker("Target Codec", selection: $state.config.codecTarget) {
                ForEach(CodecTarget.allCases) { target in
                    Text(target.rawValue).tag(target)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Codec Target")
        } footer: {
            Text("Optimises perturbations to survive compression by the selected codec. Choose the codec used by the platform you want to protect against.")
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("Masking Aggressiveness")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.config.maskingAggressiveness * 100))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(NexusTheme.warning)
                        .contentTransition(.numericText())
                }
                Slider(value: $state.config.maskingAggressiveness, in: 0...1, step: 0.05)
                    .tint(NexusTheme.warning)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Advanced")
        } footer: {
            Text("Controls how aggressively perturbations approach the audibility threshold. Higher values maximise protection strength. Default (50%) is inaudible to others on a call.")
        }
    }

    // MARK: - Technique row helper

    private func techniqueRow(_ technique: PerturbationTechnique) -> some View {
        let enabled = state.config.isTechniqueEnabled(technique)
        let tint: Color = technique.tier == .tier1 ? NexusTheme.tier1 : NexusTheme.tier2

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                state.config.toggleTechnique(technique)
            }
        } label: {
            HStack(spacing: NexusTheme.spacingMD) {
                Image(systemName: technique.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(enabled ? tint : NexusTheme.textTertiary)
                    .frame(width: 24)

                Text(technique.rawValue)
                    .font(.body)
                    .foregroundStyle(enabled ? NexusTheme.textPrimary : NexusTheme.textSecondary)

                Spacer()

                Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(enabled ? tint : Color(.systemFill))
                    .font(.system(size: 20))
                    .symbolEffect(.bounce, value: enabled)
            }
        }
        .buttonStyle(.plain)
    }
}
