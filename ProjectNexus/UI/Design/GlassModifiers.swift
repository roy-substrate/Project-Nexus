import SwiftUI

// MARK: - NexusSurfaceCardStyle (replaces GlassCardStyle)

/// Lifts content onto the Nexus card surface.
/// Uses NexusColor tokens — dark fill, 1pt border, no drop shadow.
struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(NexusColor.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(NexusColor.cardBorder, lineWidth: 1)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - GlowModifier

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.28), radius: radius, x: 0, y: 0)
    }
}

// MARK: - ShimmerModifier (no-op — kept for API compat)

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View { content }
}

// MARK: - View extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 18
    ) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Apply the Nexus dark background.
    func nexusBackground() -> some View {
        self.background(NexusColor.background.ignoresSafeArea())
    }
}

// MARK: - NexusPrimaryButtonStyle

/// Full-width accent-filled button with subtle inner shadow.
struct NexusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NexusColor.accent)
                    .overlay {
                        // Subtle inner highlight along the top edge
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.78 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - NexusSecondaryButtonStyle

/// Outline-only button in accent color.
struct NexusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(NexusColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NexusColor.accentFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(NexusColor.accent.opacity(0.35), lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.72 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - NexusDangerButtonStyle

/// Full-width danger-red filled button.
struct NexusDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NexusColor.danger)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.78 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Static style extensions

extension ButtonStyle where Self == NexusPrimaryButtonStyle {
    static var nexusPrimary: NexusPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == NexusSecondaryButtonStyle {
    static var nexusSecondary: NexusSecondaryButtonStyle { .init() }
}

extension ButtonStyle where Self == NexusDangerButtonStyle {
    static var nexusDanger: NexusDangerButtonStyle { .init() }
}
