import SwiftUI

// MARK: - GlassCard

/// A container that renders its content on a Nexus surface card.
/// Uses NexusColor tokens — dark fill, 1pt border, no drop shadow.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tintColor: Color?
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tintColor = tint
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(NexusColor.surface)

                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.07))
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            tintColor.map { $0.opacity(0.28) } ?? NexusColor.cardBorder,
                            lineWidth: 1
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - TierCard

struct TierCard: View {
    let tier: PerturbationTier
    let isEnabled: Bool
    let onToggle: () -> Void

    private var tintColor: Color {
        tier == .tier1 ? NexusColor.tier1 : NexusColor.tier2
    }

    private var iconName: String {
        tier == .tier1 ? "waveform" : "brain"
    }

    var body: some View {
        Button(action: onToggle) {
            GlassCard(tint: isEnabled ? tintColor : nil) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isEnabled ? tintColor : NexusColor.textTertiary)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isEnabled ? tintColor.opacity(0.16) : NexusColor.surfaceHigh)
                            )

                        Spacer()

                        // Hardware-style toggle pill
                        Capsule()
                            .fill(isEnabled ? tintColor : NexusColor.textTertiary.opacity(0.3))
                            .frame(width: 26, height: 14)
                            .overlay(alignment: isEnabled ? .trailing : .leading) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 10, height: 10)
                                    .padding(.horizontal, 2)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            .animation(NexusAnimation.primary, value: isEnabled)
                    }

                    Text(tier == .tier1 ? "Acoustic" : "Adversarial")
                        .font(NexusFont.sublabel())
                        .kerning(0.3)
                        .foregroundStyle(NexusColor.textTertiary)

                    Text(tier.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isEnabled ? NexusColor.textPrimary : NexusColor.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(NexusAnimation.primary, value: isEnabled)
    }
}
