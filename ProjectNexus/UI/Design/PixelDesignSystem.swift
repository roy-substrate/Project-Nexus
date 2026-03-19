import SwiftUI

// MARK: - PixelColor
//
// Warm, approachable palette inspired by calm / wellness aesthetics.
// Primary: Warm orange. Secondary: Soft amber. Background: Warm white.

enum PixelColor {
    /// Warm white canvas — soft, calm, inviting.
    static let background    = Color(red: 0.98, green: 0.97, blue: 0.95)
    /// Slightly elevated surface — white cards on cream base.
    static let surface       = Color.white
    /// Soft border — very light warm gray for card outlines.
    static let border        = Color(red: 0.88, green: 0.86, blue: 0.84)
    /// Primary text — dark charcoal, warm tone.
    static let text          = Color(red: 0.18, green: 0.16, blue: 0.14)
    /// Secondary text — medium warm gray.
    static let textSecondary = Color(red: 0.52, green: 0.50, blue: 0.48)
    /// Primary active accent — warm orange (shield on, active state).
    static let phosphor      = Color(red: 0.96, green: 0.46, blue: 0.10)
    /// Dim accent — soft orange tint for backgrounds / tracks.
    static let phosphorDim   = Color(red: 0.96, green: 0.46, blue: 0.10).opacity(0.18)
    /// Warning / alert — amber orange.
    static let warning       = Color(red: 0.96, green: 0.62, blue: 0.10)
    /// CTA blue — vibrant blue for primary action buttons.
    static let ctaBlue       = Color(red: 0.13, green: 0.59, blue: 0.95)
    /// Positive green — success states.
    static let positive      = Color(red: 0.18, green: 0.72, blue: 0.42)
}

// MARK: - PixelFont
//
// Clean, rounded system font (SF Pro). Warm and approachable — no monospaced.

enum PixelFont {
    /// General body text — readable and friendly.
    static func terminal(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    /// Hero numeric / large display — bold, rounded.
    static func hero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    /// Section headers — medium weight, slightly small.
    static func sectionHead() -> Font {
        .system(size: 12, weight: .semibold, design: .rounded)
    }
    /// Strip / status bar labels — smallest readable size.
    static func stripLabel() -> Font {
        .system(size: 10, weight: .medium, design: .rounded)
    }
    /// Small caption text.
    static func monoSmall(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}

// MARK: - DitherPatternView (no-op warm tint replacement)

/// Replaced dither with a soft gradient wash — maintains API surface.
struct DitherPatternView: View {
    var density: Float = 0.5
    var foreground: Color = PixelColor.phosphor
    var background: Color = PixelColor.background

    var body: some View {
        LinearGradient(
            colors: [foreground.opacity(Double(density) * 0.35), foreground.opacity(Double(density) * 0.12)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - ScanlineOverlay (no-op — removed CRT effect)

/// CRT scanlines removed in warm design. Modifier preserved for compatibility.
struct ScanlineOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content  // No overlay — clean warm aesthetic
    }
}

extension View {
    func scanlines() -> some View { modifier(ScanlineOverlay()) }
}

// MARK: - PixelBorder

/// Soft rounded border — 1pt warm gray stroke, generous corner radius.
struct PixelBorder: ViewModifier {
    var color: Color = PixelColor.border
    var width: CGFloat = 1

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(color, lineWidth: width)
        )
    }
}

extension View {
    func pixelBorder(_ color: Color = PixelColor.border, width: CGFloat = 1) -> some View {
        modifier(PixelBorder(color: color, width: width))
    }
}

// MARK: - PixelSurface

/// Warm white rounded card with soft drop shadow.
struct PixelSurface: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PixelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func pixelSurface(padding: CGFloat = 18) -> some View {
        modifier(PixelSurface(padding: padding))
    }
}

// MARK: - PixelButtonStyle

/// Rounded pill button — warm orange fill for active, soft gray for inactive.
struct PixelButtonStyle: ButtonStyle {
    var active: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelFont.terminal(15, weight: .semibold))
            .foregroundStyle(active ? .white : PixelColor.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                active
                    ? PixelColor.phosphor
                    : PixelColor.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: (active ? PixelColor.phosphor : Color.black).opacity(active ? 0.30 : 0.06),
                radius: active ? 8 : 4, x: 0, y: active ? 4 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PixelButtonStyle {
    static var pixel: PixelButtonStyle { .init() }
    static func pixel(active: Bool) -> PixelButtonStyle { .init(active: active) }
}

// MARK: - PixelTextProgressBar

/// Smooth rounded progress bar replacing text-art bar.
struct PixelTextProgressBar: View {
    var value: Float          // 0.0 – 1.0
    var width: Int = 10       // unused — kept for API compat
    var label: String = ""
    var color: Color = PixelColor.phosphor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label)
                    .font(PixelFont.terminal(12, weight: .medium))
                    .foregroundStyle(PixelColor.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value), height: 8)
                        .animation(PixelAnimation.arcFill, value: value)
                }
            }
            .frame(height: 8)
            HStack {
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(PixelFont.terminal(12, weight: .semibold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
    }
}

// MARK: - PhosphorGlowModifier (warm glow for active states)

/// Warm orange glow — replaces phosphor-green glow for active elements.
struct PhosphorGlow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: PixelColor.phosphor.opacity(0.40), radius: 8, x: 0, y: 0)
    }
}

extension View {
    func phosphorGlow() -> some View { modifier(PhosphorGlow()) }
}

// MARK: - NexusAnimation

/// Smooth, springy animations — warm and approachable feel.
enum PixelAnimation {
    static let primary    = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let appear     = Animation.easeOut(duration: 0.25)
    static let dismiss    = Animation.easeOut(duration: 0.18)
    static let audioPulse = Animation.easeOut(duration: 0.10)
    static let arcFill    = Animation.spring(response: 0.5, dampingFraction: 0.8)
}
