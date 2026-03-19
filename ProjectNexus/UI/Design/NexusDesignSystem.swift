import SwiftUI

// MARK: - NexusColor
//
// All tokens forward to PixelColor (warm palette).
// Legacy names preserved so all other views compile without modification.

enum NexusColor {

    // MARK: Backgrounds

    static let background       = PixelColor.background
    static let surface          = PixelColor.surface
    static let surfaceHigh      = Color(red: 0.96, green: 0.95, blue: 0.93)

    // MARK: Accent

    /// Primary accent — warm orange.
    static let accent           = PixelColor.phosphor
    static let accentFill       = PixelColor.phosphorDim
    /// Active orange — same as accent for consistency.
    static let accentEmerald    = PixelColor.phosphor
    static let accentEmeraldFill = PixelColor.phosphorDim

    // MARK: Text

    static let textPrimary      = PixelColor.text
    static let textSecondary    = PixelColor.textSecondary
    static let textTertiary     = Color(red: 0.70, green: 0.68, blue: 0.66)

    // MARK: Semantic Status

    static let danger           = Color(red: 0.92, green: 0.26, blue: 0.21)
    static let dangerFill       = Color(red: 0.92, green: 0.26, blue: 0.21).opacity(0.10)
    static let warning          = PixelColor.warning
    static let warningFill      = PixelColor.warning.opacity(0.10)
    static let positive         = PixelColor.phosphor

    // MARK: Tier Colors

    static let tier1            = Color(red: 0.96, green: 0.46, blue: 0.10)   // warm orange
    static let tier2            = Color(red: 0.13, green: 0.59, blue: 0.95)   // calm blue

    // MARK: Structural

    static let cardBorder       = PixelColor.border
    static let separator        = Color(red: 0.90, green: 0.88, blue: 0.86)
    static let stripBorder      = PixelColor.border
}

// MARK: - NexusFont
//
// All typography uses SF Pro Rounded — friendly and legible.

enum NexusFont {

    static func heroNumber(size: CGFloat = 52) -> Font {
        PixelFont.hero(size)
    }

    static func display(size: CGFloat = 52) -> Font {
        PixelFont.hero(size)
    }

    static func sectionHead() -> Font {
        PixelFont.sectionHead()
    }

    static func label() -> Font {
        PixelFont.terminal(15, weight: .semibold)
    }

    static func sublabel() -> Font {
        PixelFont.terminal(12, weight: .medium)
    }

    static func caption() -> Font {
        PixelFont.terminal(13)
    }

    static func stripLabel() -> Font {
        PixelFont.stripLabel()
    }

    static func mono(size: CGFloat = 13) -> Font {
        PixelFont.terminal(size, weight: .medium)
    }

    static func monoSmall(size: CGFloat = 11) -> Font {
        PixelFont.monoSmall(size: size)
    }
}

// MARK: - NexusSurface ViewModifier (rounded warm card)

struct NexusSurface: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PixelColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func nexusSurface(cornerRadius: CGFloat = 20, padding: CGFloat = 18) -> some View {
        modifier(NexusSurface(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Animation constants (spring-based, warm feel)

enum NexusAnimation {
    static let primary    = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let appear     = Animation.easeOut(duration: 0.25)
    static let dismiss    = Animation.easeOut(duration: 0.18)
    static let audioPulse = Animation.easeOut(duration: 0.10)
    static let arcFill    = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - Hex Color init

extension Color {
    /// Convenience initializer from a CSS hex string (e.g. "#F5761A").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
