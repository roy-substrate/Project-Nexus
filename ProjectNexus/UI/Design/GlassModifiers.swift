import SwiftUI

// MARK: - Card style (replaces dark glass)

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = NexusTheme.radiusMD
    var padding: CGFloat = NexusTheme.spacingMD

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(NexusTheme.cardFill)
                    .shadow(color: NexusTheme.cardShadow, radius: 8, x: 0, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(NexusTheme.cardStroke, lineWidth: 0.5)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Subtle glow (light-mode friendly)

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.22), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.10), radius: radius * 1.8, x: 0, y: 0)
    }
}

// MARK: - Shimmer (removed animation for minimal aesthetic; kept API)

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - View extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = NexusTheme.radiusMD,
        padding: CGFloat = NexusTheme.spacingMD
    ) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func glow(color: Color, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Apply the light app background to any view.
    func nexusBackground() -> some View {
        self.background {
            NexusTheme.backgroundPrimary
                .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Reusable primary button style

struct NexusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NexusTheme.bodyFont.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                    .fill(NexusTheme.accentBlue)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            }
    }
}

/// Ghost / secondary button — outlined, accent-colored label.
struct NexusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NexusTheme.bodyFont.weight(.medium))
            .foregroundStyle(NexusTheme.accentBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                    .fill(NexusTheme.backgroundTertiary)
                    .overlay {
                        RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                            .strokeBorder(NexusTheme.cardStroke, lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.80 : 1.0)
            }
    }
}

extension ButtonStyle where Self == NexusPrimaryButtonStyle {
    static var nexusPrimary: NexusPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == NexusSecondaryButtonStyle {
    static var nexusSecondary: NexusSecondaryButtonStyle { .init() }
}
