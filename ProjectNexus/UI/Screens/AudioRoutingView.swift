import SwiftUI

struct AudioRoutingView: View {
    @Bindable var state: AppState

    var body: some View {
        ZStack {
            NexusTheme.backgroundPrimary.ignoresSafeArea()
            NexusTheme.backgroundGradient.ignoresSafeArea().opacity(0.4)
            ParticleFieldView(particleCount: 20, isActive: false).ignoresSafeArea().opacity(0.3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: NexusTheme.spacingLG) {
                    headerSection

                    speakerCard
                    voipCard
                    routeInfoCard
                }
                .padding(.horizontal, NexusTheme.spacingMD)
                .padding(.bottom, 100)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("AUDIO ROUTING")
                .font(NexusTheme.captionFont)
                .foregroundStyle(NexusTheme.textTertiary)
                .tracking(2)
            Spacer()
        }
        .padding(.top, NexusTheme.spacingSM)
    }

    private var speakerCard: some View {
        Button {
            withAnimation(.bouncy) {
                state.audioMode = .speakerPlayback
            }
        } label: {
            GlassCard(tint: state.audioMode == .speakerPlayback ? NexusTheme.accentCyan : nil) {
                VStack(alignment: .leading, spacing: NexusTheme.spacingMD) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(NexusTheme.accentCyan)

                        Spacer()

                        if state.audioMode == .speakerPlayback {
                            Text("ACTIVE")
                                .font(NexusTheme.monoSmall)
                                .foregroundStyle(NexusTheme.accentGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule().fill(NexusTheme.accentGreen.opacity(0.15))
                                }
                        }
                    }

                    Text("Speaker Playback")
                        .font(NexusTheme.headlineFont)
                        .foregroundStyle(NexusTheme.textPrimary)

                    Text("Perturbation plays through device speaker. Place phone near the recording device for maximum effect.")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textSecondary)
                        .lineSpacing(3)

                    HStack(spacing: NexusTheme.spacingMD) {
                        featureTag("No Setup", icon: "checkmark.circle")
                        featureTag("Any App", icon: "app.badge")
                        featureTag("Offline", icon: "wifi.slash")
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var voipCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingMD) {
                HStack {
                    Image(systemName: "phone.arrow.up.right.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(NexusTheme.textTertiary)

                    Spacer()

                    Text("COMING SOON")
                        .font(NexusTheme.monoSmall)
                        .foregroundStyle(NexusTheme.accentPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule().fill(NexusTheme.accentPurple.opacity(0.15))
                        }
                }

                Text("VoIP Mix")
                    .font(NexusTheme.headlineFont)
                    .foregroundStyle(NexusTheme.textTertiary)

                Text("Mix perturbation directly into outgoing VoIP audio stream. Requires the app to act as a VoIP audio source via CallKit or WebRTC proxy.")
                    .font(NexusTheme.captionFont)
                    .foregroundStyle(NexusTheme.textTertiary)
                    .lineSpacing(3)

                HStack(spacing: NexusTheme.spacingMD) {
                    featureTag("Direct Mix", icon: "waveform.path", disabled: true)
                    featureTag("Inaudible", icon: "ear", disabled: true)
                }
            }
        }
        .opacity(0.6)
    }

    private var routeInfoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                Text("CURRENT ROUTE")
                    .font(NexusTheme.captionFont)
                    .foregroundStyle(NexusTheme.textTertiary)
                    .tracking(1)

                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(NexusTheme.accentCyan)
                    Text(AudioSessionConfigurator.shared.currentRoute)
                        .font(NexusTheme.monoFont)
                        .foregroundStyle(NexusTheme.textPrimary)
                }

                Divider().background(NexusTheme.glassStroke)

                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(
                            AudioSessionConfigurator.shared.isMicrophoneAvailable
                                ? NexusTheme.accentGreen
                                : NexusTheme.accentRed
                        )
                    Text(AudioSessionConfigurator.shared.isMicrophoneAvailable ? "Microphone Available" : "No Microphone")
                        .font(NexusTheme.monoFont)
                        .foregroundStyle(NexusTheme.textPrimary)
                }
            }
        }
    }

    private func featureTag(_ text: String, icon: String, disabled: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(disabled ? NexusTheme.textTertiary : NexusTheme.accentCyan)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(disabled ? NexusTheme.glassFill : NexusTheme.accentCyan.opacity(0.1))
        }
    }
}
