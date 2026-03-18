import SwiftUI

/// Design token compatibility shim.
/// All values now forward to PixelColor / NexusColor (which itself forwards to PixelColor).
/// No existing code needs to change — add new code using PixelColor directly.
enum NexusTheme {

    // MARK: - Background surfaces

    static let background                  = PixelColor.background
    static let backgroundSecondary         = PixelColor.surface
    static let backgroundGrouped           = PixelColor.background
    static let backgroundGroupedSecondary  = PixelColor.surface

    // MARK: - Brand / interactive

    static let accent     = PixelColor.text
    static let accentFill = Color.white.opacity(0.05)

    // MARK: - Tier colours (both white in pixel aesthetic)

    static let tier1 = PixelColor.text
    static let tier2 = PixelColor.text

    // MARK: - Semantic status

    static let positive = PixelColor.phosphor
    static let warning  = PixelColor.warning
    static let danger   = PixelColor.warning

    // MARK: - Text

    static let textPrimary    = PixelColor.text
    static let textSecondary  = PixelColor.textSecondary
    static let textTertiary   = Color.white.opacity(0.2)
    static let textQuaternary = Color.white.opacity(0.12)

    // MARK: - Surface / separator

    static let separator              = Color.white.opacity(0.15)
    static let cardBackground         = PixelColor.surface
    static let cardStroke             = PixelColor.border

    // MARK: - Legacy aliases

    static let backgroundPrimary          = background
    static let backgroundTertiary         = backgroundGroupedSecondary
    static let accentBlue                 = PixelColor.text
    static let accentBlueSoft             = Color.white.opacity(0.05)
    static let accentIndigoMuted          = Color.white.opacity(0.08)
    static let accentCyan                 = PixelColor.text
    static let accentPurple               = PixelColor.text
    static let accentMagenta              = PixelColor.text
    static let accentGreen                = PixelColor.phosphor
    static let accentOrange               = PixelColor.warning
    static let accentRed                  = PixelColor.warning
    static let glassFill                  = PixelColor.surface
    static let glassStroke                = PixelColor.border
    static let glassHighlight             = Color.white.opacity(0.06)
    static let glowCyan                   = Color.clear
    static let glowPurple                 = Color.clear

    // MARK: - Typography (legacy aliases — prefer PixelFont)

    static let displayFont   = PixelFont.hero(34)
    static let titleFont     = PixelFont.terminal(22, weight: .bold)
    static let headlineFont  = PixelFont.terminal(17, weight: .bold)
    static let bodyFont      = PixelFont.terminal(16)
    static let subheadFont   = PixelFont.terminal(14)
    static let captionFont   = PixelFont.terminal(12)
    static let monoFont      = PixelFont.terminal(16, weight: .medium)
    static let monoSmall     = PixelFont.monoSmall()

    // MARK: - Spacing (8pt grid)

    static let spacingXS:  CGFloat = 4
    static let spacingSM:  CGFloat = 8
    static let spacingMD:  CGFloat = 16
    static let spacingLG:  CGFloat = 24
    static let spacingXL:  CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner radii (all 0 in pixel aesthetic)

    static let radiusSM: CGFloat = 0
    static let radiusMD: CGFloat = 0
    static let radiusLG: CGFloat = 0
    static let radiusXL: CGFloat = 0

    // MARK: - Gradients (replaced by dither patterns — kept for compat)

    static let backgroundGradient = LinearGradient(
        colors: [PixelColor.background, PixelColor.surface],
        startPoint: .top, endPoint: .bottom
    )

    static let spectrumGradient = LinearGradient(
        colors: [PixelColor.text, PixelColor.phosphor],
        startPoint: .leading, endPoint: .trailing
    )

    static let cyanGradient = LinearGradient(
        colors: [PixelColor.text, PixelColor.text.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [PixelColor.textSecondary, PixelColor.textSecondary.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
