import SwiftUI

// MARK: - GlassCard

/// A container that renders its content on a raised card surface.
///
/// Uses the system's secondary grouped background so it lifts cleanly from the
/// page in both light and dark mode without any hardcoded colours.
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
                        .fill(NexusTheme.cardBackground)

                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.09))
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            tintColor.map { $0.opacity(0.25) } ?? NexusTheme.cardStroke,
                            lineWidth: tintColor != nil ? 1 : 0.5
                        )
                }
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 0)
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
        tier == .tier1 ? NexusTheme.tier1 : NexusTheme.tier2
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isEnabled ? tintColor : NexusTheme.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isEnabled ? tintColor.opacity(0.12) : Color(.quaternarySystemFill))
                            )

                        Spacer()

                        // On/off indicator dot
                        Circle()
                            .fill(isEnabled ? tintColor : Color(.systemFill))
                            .frame(width: 8, height: 8)
                    }

                    Text(tier == .tier1 ? "Acoustic" : "Adversarial")
                        .font(.caption)
                        .foregroundStyle(NexusTheme.textTertiary)

                    Text(tier.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isEnabled ? NexusTheme.textPrimary : NexusTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isEnabled)
    }
}
