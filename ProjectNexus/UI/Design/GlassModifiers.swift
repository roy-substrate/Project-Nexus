import SwiftUI

// MARK: - Card style

/// Lifts content onto a card surface using the system's secondary grouped background.
/// Matches iOS Settings-style inset cards — clean, no glow, adaptive.
struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = NexusTheme.radiusMD
    var padding: CGFloat = NexusTheme.spacingMD

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(NexusTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(NexusTheme.cardStroke, lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Glow (intentionally subtle for light mode)

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.18), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Shimmer (no-op — removed; presence kept for API compat)

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View { content }
}

// MARK: - View extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = NexusTheme.radiusMD,
        padding: CGFloat = NexusTheme.spacingMD
    ) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Apply the system grouped background (adapts to light/dark mode).
    func nexusBackground() -> some View {
        self.background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Primary button style  (solid, full-width, system blue)

struct NexusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.80 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Outlined secondary button — sits below a primary CTA.
struct NexusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Color.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                    .fill(Color.blue.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: NexusTheme.radiusMD, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.75 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NexusPrimaryButtonStyle {
    static var nexusPrimary: NexusPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == NexusSecondaryButtonStyle {
    static var nexusSecondary: NexusSecondaryButtonStyle { .init() }
}
