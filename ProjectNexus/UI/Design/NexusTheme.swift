import SwiftUI

enum NexusTheme {
    // MARK: - Colors

    /// Page background — light warm gray (matching reference design)
    static let backgroundPrimary = Color(red: 0.925, green: 0.925, blue: 0.929)
    /// Slightly lighter surface for layered cards
    static let backgroundSecondary = Color(red: 0.960, green: 0.960, blue: 0.964)
    /// Card/sheet surface — near white
    static let backgroundTertiary = Color(red: 0.980, green: 0.980, blue: 0.984)

    /// Primary interactive — blue/indigo (matching reference highlight color)
    static let accentBlue   = Color(red: 0.231, green: 0.231, blue: 1.000)
    /// Softer blue for secondary interactive elements
    static let accentBlueSoft = Color(red: 0.400, green: 0.400, blue: 0.980)
    /// Muted indigo for badge backgrounds
    static let accentIndigoMuted = Color(red: 0.820, green: 0.820, blue: 0.980)

    // Semantic aliases (kept for compatibility)
    static let accentCyan    = accentBlue
    static let accentPurple  = accentBlueSoft
    static let accentMagenta = accentBlue
    static let accentGreen   = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let accentOrange  = Color(red: 0.95, green: 0.55, blue: 0.10)
    static let accentRed     = Color(red: 0.90, green: 0.20, blue: 0.25)

    // MARK: - Text

    static let textPrimary   = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let textSecondary = Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.55)
    static let textTertiary  = Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.30)
    static let textAccent    = accentBlue

    // MARK: - Card / border

    static let cardStroke    = Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.08)
    static let cardFill      = Color.white
    static let cardShadow    = Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.06)

    // Legacy glass aliases mapped to light equivalents
    static let glassStroke    = cardStroke
    static let glassFill      = cardFill
    static let glassHighlight = Color.white

    // MARK: - Gradients

    /// Full-screen background — subtle light gradient
    static let backgroundGradient = LinearGradient(
        colors: [backgroundPrimary, backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cyanGradient = LinearGradient(
        colors: [accentBlue, accentBlueSoft],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [accentBlueSoft, accentIndigoMuted],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let spectrumGradient = LinearGradient(
        colors: [accentBlue, accentBlueSoft, accentIndigoMuted],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typography

    /// Large display title
    static let displayFont  = Font.system(size: 26, weight: .semibold, design: .default)
    /// Section headings
    static let headlineFont = Font.system(size: 16, weight: .semibold, design: .default)
    /// Body copy
    static let bodyFont     = Font.system(size: 14, weight: .regular, design: .default)
    /// Labels and captions
    static let captionFont  = Font.system(size: 12, weight: .medium, design: .default)
    /// Data / metrics — monospaced
    static let monoFont     = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoSmall    = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Spacing

    static let spacingXS:  CGFloat = 4
    static let spacingSM:  CGFloat = 8
    static let spacingMD:  CGFloat = 16
    static let spacingLG:  CGFloat = 24
    static let spacingXL:  CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner radii

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 14
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // MARK: - Glow / shadow tints (light-mode friendly)

    static let glowCyan   = accentBlue.opacity(0.18)
    static let glowPurple = accentBlueSoft.opacity(0.18)
}
