import SwiftUI

// MARK: - GlassCardStyle (replaced by PixelSurface — kept for API compat)

/// Legacy name kept so other views still compile.
/// All visual properties now forward to the pixel design system.
struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 0   // always 0 — pixel aesthetic
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PixelColor.surface)
            .pixelBorder()
    }
}

// MARK: - GlowModifier (no-op except phosphor glow — kept for API compat)

/// Drop shadows are removed in the pixel aesthetic.
/// Only phosphor glow (radius 1-2) is permitted on active green text — use .phosphorGlow().
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        // No-op: drop shadows removed. Phosphor glow is applied via .phosphorGlow().
        content
    }
}

// MARK: - ShimmerModifier (no-op — kept for API compat)

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View { content }
}

// MARK: - View extensions

extension View {
    func glassCard(
        cornerRadius: CGFloat = 0,
        padding: CGFloat = 18
    ) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func glow(color: Color, radius: CGFloat = 10) -> some View {
        // No-op in pixel aesthetic — use .phosphorGlow() for active green text only.
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Apply the pixel black background.
    func nexusBackground() -> some View {
        self.background(PixelColor.background.ignoresSafeArea())
    }
}

// MARK: - NexusPrimaryButtonStyle → forwards to PixelButtonStyle

struct NexusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelFont.terminal(16, weight: .medium))
            .foregroundStyle(PixelColor.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(configuration.isPressed ? Color.white.opacity(0.08) : .black)
            .pixelBorder()
            .cornerRadius(0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - NexusSecondaryButtonStyle → forwards to PixelButtonStyle

struct NexusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelFont.terminal(16, weight: .regular))
            .foregroundStyle(PixelColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(configuration.isPressed ? Color.white.opacity(0.05) : .black)
            .pixelBorder(PixelColor.border.opacity(0.5))
            .cornerRadius(0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - NexusDangerButtonStyle

struct NexusDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelFont.terminal(16, weight: .medium))
            .foregroundStyle(PixelColor.warning)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(configuration.isPressed ? Color.white.opacity(0.05) : .black)
            .pixelBorder(PixelColor.warning)
            .cornerRadius(0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
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
