import SwiftUI

// MARK: - PixelColor

/// Two-color phosphor palette for the pixel/terminal aesthetic.
/// Background: pure black. Text/borders: near-white.
/// Active state accent: phosphor green #39FF14 ONLY.
enum PixelColor {
    /// Pure black canvas — no blue tint, no surface lift.
    static let background    = Color(red: 0, green: 0, blue: 0)
    /// Barely-lifted surface — 5% grey for subtle texture behind cards.
    static let surface       = Color(red: 0.05, green: 0.05, blue: 0.05)
    /// Pixel-perfect 1px border — white at 0.85 opacity.
    static let border        = Color.white.opacity(0.85)
    /// Primary text — #F0F0F0, slightly warm off-white.
    static let text          = Color(red: 0.94, green: 0.94, blue: 0.94)
    /// Secondary text — white at 0.45 opacity, dimmer terminal readout.
    static let textSecondary = Color.white.opacity(0.45)
    /// Phosphor green — #39FF14. ONLY used for active shield state.
    static let phosphor      = Color(red: 0.224, green: 1.0, blue: 0.078)
    /// Dim phosphor — for inactive phosphor indicators, progress track.
    static let phosphorDim   = Color(red: 0.224, green: 1.0, blue: 0.078).opacity(0.35)
    /// Warning amber — kept minimal, only for latency alerts.
    static let warning       = Color(red: 1.0, green: 0.7, blue: 0.18)
}

// MARK: - PixelFont

/// All typography is SF Mono (monospaced). No San Francisco, no rounded.
enum PixelFont {
    /// General terminal readout — body-level monospaced.
    static func terminal(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    /// Hero numeric display — large, bold, terminal feel.
    static func hero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
    /// Section headers — medium weight, tight spacing.
    static func sectionHead() -> Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }
    /// Strip / status bar labels — smallest readable size.
    static func stripLabel() -> Font {
        .system(size: 9, weight: .medium, design: .monospaced)
    }
    /// Mono caption — 12pt for axis labels, supplementary info.
    static func monoSmall(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - DitherPatternView

/// Bayer 4×4 ordered-dither pattern rendered via Canvas.
/// Use density 0.04 for surface texture, 0.15 for active phosphor fill.
struct DitherPatternView: View {
    /// 0.0 = all background, 1.0 = all foreground.
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

/// CRT simulation: horizontal scanlines every 2px at 3% black opacity.
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
    /// Apply CRT scanline overlay — call on root view.
    func scanlines() -> some View { modifier(ScanlineOverlay()) }
}

// MARK: - PixelBorder

/// 1px solid rectangular border — no corner radius, no glow.
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
    /// Apply a pixel-perfect 1px rectangular border.
    func pixelBorder(_ color: Color = PixelColor.border, width: CGFloat = 1) -> some View {
        modifier(PixelBorder(color: color, width: width))
    }
}

// MARK: - PixelSurface

/// Square-cornered card surface: very-dark fill + 1px white border.
/// Replaces NexusSurface and GlassCardStyle.
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

/// Square-cornered button — monospaced label, pixel border, no rounded corners.
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

/// Text-art progress bar: `[██████░░░░ 78%]`
struct PixelTextProgressBar: View {
    var value: Float          // 0.0 – 1.0
    var width: Int = 10       // total block count
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

// MARK: - PhosphorGlowModifier

/// Phosphor-green text shadow — ONLY for active green text.
struct PhosphorGlow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: PixelColor.phosphor.opacity(0.6), radius: 1, x: 0, y: 0)
    }
}

extension View {
    /// Apply phosphor glow shadow — only use on active phosphor-green text.
    func phosphorGlow() -> some View { modifier(PhosphorGlow()) }
}

// MARK: - NexusAnimation compatibility shim

/// Terminal-aesthetic animations — crisp and fast, no bounce.
enum PixelAnimation {
    static let primary   = Animation.easeOut(duration: 0.15)
    static let appear    = Animation.easeOut(duration: 0.2)
    static let dismiss   = Animation.easeOut(duration: 0.12)
    static let audioPulse = Animation.easeOut(duration: 0.08)
    static let arcFill   = Animation.easeOut(duration: 0.3)
}
