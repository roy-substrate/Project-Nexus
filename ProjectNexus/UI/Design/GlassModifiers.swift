import SwiftUI

// MARK: - PixelColor

enum PixelColor {
    static let background    = Color(red: 0, green: 0, blue: 0)
    static let surface       = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let border        = Color.white.opacity(0.85)
    static let text          = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let textSecondary = Color.white.opacity(0.45)
    static let phosphor      = Color(red: 0.224, green: 1.0, blue: 0.078)
    static let phosphorDim   = Color(red: 0.224, green: 1.0, blue: 0.078).opacity(0.35)
    static let warning       = Color(red: 1.0, green: 0.7, blue: 0.18)
}

// MARK: - PixelFont

enum PixelFont {
    static func terminal(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func hero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
    static func sectionHead() -> Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }
    static func stripLabel() -> Font {
        .system(size: 9, weight: .medium, design: .monospaced)
    }
    static func monoSmall(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - DitherPatternView

struct DitherPatternView: View {
    var density: Float = 0.5
    var foreground: Color = PixelColor.phosphor
    var background: Color = .black

    private let bayer4: [[Int]] = [
        [ 0,  8,  2, 10],
        [12,  4, 14,  6],
        [ 3, 11,  1,  9],
        [15,  7, 13,  5]
    ]

    var body: some View {
        Canvas { context, size in
            for py in 0..<Int(size.height) {
                for px in 0..<Int(size.width) {
                    let threshold = Float(bayer4[py % 4][px % 4]) / 16.0
                    let color: Color = density > threshold ? foreground : background
                    context.fill(
                        Path(CGRect(x: px, y: py, width: 1, height: 1)),
                        with: .color(color)
                    )
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - ScanlineOverlay

struct ScanlineOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(
            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black.opacity(0.03))
                    )
                    y += 2
                }
            }
            .allowsHitTesting(false)
        )
    }
}

extension View {
    func scanlines() -> some View { modifier(ScanlineOverlay()) }
}

// MARK: - PixelBorder

struct PixelBorder: ViewModifier {
    var color: Color = PixelColor.border
    var width: CGFloat = 1

    func body(content: Content) -> some View {
        content.overlay(
            Rectangle()
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

struct PixelSurface: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PixelColor.surface)
            .pixelBorder()
    }
}

extension View {
    func pixelSurface(padding: CGFloat = 18) -> some View {
        modifier(PixelSurface(padding: padding))
    }
}

// MARK: - PixelButtonStyle

struct PixelButtonStyle: ButtonStyle {
    var active: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PixelFont.terminal(14, weight: .medium))
            .foregroundStyle(active ? PixelColor.phosphor : PixelColor.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color.white.opacity(0.08) : .black)
            .pixelBorder(active ? PixelColor.phosphor : PixelColor.border)
            .cornerRadius(0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PixelButtonStyle {
    static var pixel: PixelButtonStyle { .init() }
    static func pixel(active: Bool) -> PixelButtonStyle { .init(active: active) }
}

// MARK: - PixelTextProgressBar

struct PixelTextProgressBar: View {
    var value: Float
    var width: Int = 10
    var label: String = ""
    var color: Color = PixelColor.phosphor

    private var filled: Int { Int(value * Float(width)) }

    var body: some View {
        HStack(spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(PixelFont.terminal(12, weight: .medium))
                    .foregroundStyle(PixelColor.textSecondary)
            }
            Text("[")
                .font(PixelFont.terminal(12))
                .foregroundStyle(color)
            Text(String(repeating: "█", count: filled) +
                 String(repeating: "░", count: width - filled))
                .font(PixelFont.terminal(12))
                .foregroundStyle(color)
            Text("\(Int(value * 100))%]")
                .font(PixelFont.terminal(12))
                .foregroundStyle(color)
        }
        .contentTransition(.numericText())
    }
}

// MARK: - PhosphorGlow

struct PhosphorGlow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: PixelColor.phosphor.opacity(0.6), radius: 1, x: 0, y: 0)
    }
}

extension View {
    func phosphorGlow() -> some View { modifier(PhosphorGlow()) }
}

// MARK: - PixelAnimation

enum PixelAnimation {
    static let primary    = Animation.easeOut(duration: 0.15)
    static let appear     = Animation.easeOut(duration: 0.2)
    static let dismiss    = Animation.easeOut(duration: 0.12)
    static let audioPulse = Animation.easeOut(duration: 0.08)
    static let arcFill    = Animation.easeOut(duration: 0.3)
}

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
