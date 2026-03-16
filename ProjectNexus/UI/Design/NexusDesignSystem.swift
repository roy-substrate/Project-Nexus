import SwiftUI

// MARK: - NexusColor

/// All color tokens for Nexus Shield's dark-native design system.
/// Every value is a deliberate design decision — nothing is a system default.
enum NexusColor {

    // MARK: Backgrounds

    /// Primary canvas: near-black with a cool blue-black undertone.
    static let background       = Color(hex: "#0A0A0F")
    /// Card / section surface — lifts one step from background.
    static let surface          = Color(hex: "#111118")
    /// Modal, overlay, popover surface — two steps from background.
    static let surfaceHigh      = Color(hex: "#1A1A24")

    // MARK: Accent

    /// Electric indigo-blue — the brand interactive color.
    static let accent           = Color(hex: "#4B7BFF")
    /// Soft fill version of accent (for backgrounds, tints).
    static let accentFill       = Color(hex: "#4B7BFF").opacity(0.12)
    /// Cold emerald — ONLY for "active / protected" states.
    static let accentEmerald    = Color(hex: "#00E5A0")
    /// Soft fill version of emerald.
    static let accentEmeraldFill = Color(hex: "#00E5A0").opacity(0.12)

    // MARK: Text

    /// Slightly cool white — primary labels.
    static let textPrimary      = Color(hex: "#F0F0F8")
    /// Muted purple-grey — secondary descriptions.
    static let textSecondary    = Color(hex: "#6B6B7E")
    /// Near-invisible — tertiary labels, placeholders.
    static let textTertiary     = Color(hex: "#3A3A4E")

    // MARK: Semantic Status

    static let danger           = Color(hex: "#FF4B4B")
    static let dangerFill       = Color(hex: "#FF4B4B").opacity(0.12)
    static let warning          = Color(hex: "#FFB347")
    static let warningFill      = Color(hex: "#FFB347").opacity(0.12)
    static let positive         = Color(hex: "#00E5A0")   // alias for emerald

    // MARK: Tier Colors

    /// Tier 1 — Acoustic (indigo-teal, brighter for dark surfaces)
    static let tier1            = Color(hex: "#4B7BFF")
    /// Tier 2 — Adversarial ML (violet-purple)
    static let tier2            = Color(hex: "#A259FF")

    // MARK: Structural

    /// Card border — 1 pt, barely-there depth signal.
    static let cardBorder       = Color.white.opacity(0.06)
    /// Separator line between sections.
    static let separator        = Color.white.opacity(0.08)
    /// Status strip top border.
    static let stripBorder      = Color.white.opacity(0.06)
}

// MARK: - NexusFont

/// Typography helpers calibrated to the design spec.
/// Always prefer these over raw `.system()` calls in views.
enum NexusFont {

    // MARK: Hero

    /// Hero numerics — jam score, session timer. SF Pro Rounded, Bold.
    static func heroNumber(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // MARK: Display

    /// Onboarding headline, "All set." — tight tracking.
    static func display(size: CGFloat = 52) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    // MARK: Section / Card Heads

    /// Section titles — SF Pro Display feel via .semibold at 17.
    static func sectionHead() -> Font {
        .system(size: 17, weight: .semibold, design: .default)
    }

    // MARK: Labels

    /// Component labels — 14pt Medium.
    static func label() -> Font {
        .system(size: 14, weight: .medium, design: .default)
    }

    /// Slightly smaller label used for tier sublabels.
    static func sublabel() -> Font {
        .system(size: 11, weight: .medium, design: .default)
    }

    // MARK: Captions

    /// Caption text — 12pt Regular, slightly open tracking.
    static func caption() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    /// Status strip label — 9pt Medium.
    static func stripLabel() -> Font {
        .system(size: 9, weight: .medium, design: .default)
    }

    // MARK: Monospaced Data

    /// Precision data readout — SF Mono, 13pt.
    static func mono(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Small mono — 11pt for frequency axis labels.
    static func monoSmall(size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - NexusSurface ViewModifier

/// Applies the standard Nexus card surface: dark fill + 1pt border, no shadow.
/// Depth comes from background contrast, not drop shadows.
struct NexusSurface: ViewModifier {
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
    }
}

extension View {
    /// Wraps content in the Nexus card surface style.
    func nexusSurface(cornerRadius: CGFloat = 20, padding: CGFloat = 18) -> some View {
        modifier(NexusSurface(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Animation constants

/// Shared animation presets. Tuned to feel physical, not bouncy.
enum NexusAnimation {
    /// Primary state transition — crisp, no jitter.
    static let primary    = Animation.spring(response: 0.38, dampingFraction: 0.9)
    /// Appearing / revealing elements.
    static let appear     = Animation.spring(response: 0.5, dampingFraction: 0.88)
    /// Dismissal / fade — never spring.
    static let dismiss    = Animation.easeOut(duration: 0.22)
    /// Audio-reactive pulse — tight, fast.
    static let audioPulse = Animation.interpolatingSpring(stiffness: 180, damping: 20)
    /// ASR arc fill — smooth, slow.
    static let arcFill    = Animation.spring(response: 0.6, dampingFraction: 0.92)
}

// MARK: - Hex Color init

extension Color {
    /// Convenience initializer from a CSS hex string (e.g. "#4B7BFF").
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
