import SwiftUI

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tintColor: Color?
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = NexusTheme.radiusMD,
        tint: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tintColor = tint
        self.content = content
    }

    var body: some View {
        content()
            .padding(NexusTheme.spacingMD)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(NexusTheme.glassFill)

                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.08))
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    (tintColor ?? .white).opacity(0.2),
                                    NexusTheme.glassStroke,
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct TierCard: View {
    let tier: PerturbationTier
    let isEnabled: Bool
    let onToggle: () -> Void

    private var tintColor: Color {
        tier == .tier1 ? NexusTheme.accentCyan : NexusTheme.accentPurple
    }

    private var iconName: String {
        tier == .tier1 ? "waveform" : "brain"
    }

    var body: some View {
        Button(action: onToggle) {
            GlassCard(tint: isEnabled ? tintColor : nil) {
                VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                    HStack {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(isEnabled ? tintColor : NexusTheme.textTertiary)

                        Spacer()

                        Circle()
                            .fill(isEnabled ? tintColor : NexusTheme.textTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }

                    Text(tier == .tier1 ? "TIER 1" : "TIER 2")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                        .tracking(1.5)

                    Text(tier.rawValue)
                        .font(NexusTheme.headlineFont)
                        .foregroundStyle(isEnabled ? NexusTheme.textPrimary : NexusTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isEnabled)
    }
}
