import SwiftUI

// MARK: - GlassCard

/// A warm white card container with soft drop shadow and rounded corners.
/// Matches Headspace-inspired calm aesthetic.
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
                            .fill(tint.opacity(0.08))
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            tintColor.map { $0.opacity(0.22) } ?? NexusColor.cardBorder,
                            lineWidth: 1
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: (tintColor ?? Color.black).opacity(tintColor != nil ? 0.12 : 0.06),
                radius: tintColor != nil ? 14 : 10,
                x: 0, y: tintColor != nil ? 6 : 4
            )
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

    private var tierLabel: String {
        tier == .tier1 ? "Acoustic" : "Adversarial"
    }

    var body: some View {
        Button(action: onToggle) {
            GlassCard(tint: isEnabled ? tintColor : nil) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Icon badge
                        Image(systemName: iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isEnabled ? tintColor : NexusColor.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isEnabled ? tintColor.opacity(0.14) : NexusColor.surfaceHigh)
                            )

                        Spacer()

                        // Pill toggle
                        Capsule()
                            .fill(isEnabled ? tintColor : NexusColor.textTertiary.opacity(0.25))
                            .frame(width: 44, height: 24)
                            .overlay(alignment: isEnabled ? .trailing : .leading) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 18, height: 18)
                                    .padding(.horizontal, 3)
                                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                            }
                            .animation(NexusAnimation.primary, value: isEnabled)
                    }

                    Text(tierLabel)
                        .font(NexusFont.sublabel())
                        .foregroundStyle(NexusColor.textTertiary)

                    Text(tier.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(isEnabled ? NexusColor.textPrimary : NexusColor.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(NexusAnimation.primary, value: isEnabled)
    }
}
