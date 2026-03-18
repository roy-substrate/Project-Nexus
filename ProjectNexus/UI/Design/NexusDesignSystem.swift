import SwiftUI

// MARK: - NexusColor
//
// All tokens now forward to PixelColor / pixel palette.
// Legacy names preserved so all other views compile without modification.

enum NexusColor {

    // MARK: Backgrounds

    static let background       = PixelColor.background
    static let surface          = PixelColor.surface
    static let surfaceHigh      = Color(red: 0.08, green: 0.08, blue: 0.08)

    // MARK: Accent (pixel aesthetic: phosphor green for active, white for inactive)

    /// Legacy accent — now maps to white border/text.
    static let accent           = PixelColor.text
    static let accentFill       = Color.white.opacity(0.05)
    /// Active phosphor green — ONLY used for active shield state.
    static let accentEmerald    = PixelColor.phosphor
    static let accentEmeraldFill = PixelColor.phosphorDim

    // MARK: Text

    static let textPrimary      = PixelColor.text
    static let textSecondary    = PixelColor.textSecondary
    static let textTertiary     = Color.white.opacity(0.2)

    // MARK: Semantic Status

    static let danger           = PixelColor.warning
    static let dangerFill       = PixelColor.warning.opacity(0.1)
    static let warning          = PixelColor.warning
    static let warningFill      = PixelColor.warning.opacity(0.1)
    static let positive         = PixelColor.phosphor

    // MARK: Tier Colors (now both white — no color in inactive state)

    static let tier1            = PixelColor.text
    static let tier2            = PixelColor.text

    // MARK: Structural

    static let cardBorder       = PixelColor.border
    static let separator        = Color.white.opacity(0.15)
    static let stripBorder      = Color.white.opacity(0.85)
}

// MARK: - NexusFont
//
// All typography now forwards to PixelFont (SF Mono exclusively).

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
        PixelFont.terminal(14, weight: .medium)
    }

    static func sublabel() -> Font {
        PixelFont.terminal(11, weight: .medium)
    }

    static func caption() -> Font {
        PixelFont.terminal(12)
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

// MARK: - NexusSurface ViewModifier (square corners, pixel border)

struct NexusSurface: ViewModifier {
    var cornerRadius: CGFloat = 0    // always 0 — pixel aesthetic
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PixelColor.surface)
            .pixelBorder()
    }
}

extension View {
    func nexusSurface(cornerRadius: CGFloat = 0, padding: CGFloat = 18) -> some View {
        modifier(NexusSurface(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Animation constants (crisp, no spring bounce)

enum NexusAnimation {
    static let primary    = Animation.easeOut(duration: 0.15)
    static let appear     = Animation.easeOut(duration: 0.2)
    static let dismiss    = Animation.easeOut(duration: 0.12)
    static let audioPulse = Animation.easeOut(duration: 0.08)
    static let arcFill    = Animation.easeOut(duration: 0.3)
}

// MARK: - Hex Color init

extension Color {
    /// Convenience initializer from a CSS hex string (e.g. "#39FF14").
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
