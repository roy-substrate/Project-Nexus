import SwiftUI

/// Design token compatibility shim — warm palette.
/// All values forward to PixelColor / NexusColor.
enum NexusTheme {

    // MARK: - Background surfaces

    static let background                  = PixelColor.background
    static let backgroundSecondary         = NexusColor.surfaceHigh
    static let backgroundGrouped           = PixelColor.background
    static let backgroundGroupedSecondary  = NexusColor.surfaceHigh

    // MARK: - Brand / interactive

    static let accent     = PixelColor.phosphor
    static let accentFill = PixelColor.phosphorDim

    // MARK: - Tier colours

    static let tier1 = NexusColor.tier1    // warm orange
    static let tier2 = NexusColor.tier2    // calm blue

    // MARK: - Semantic status

    static let positive = PixelColor.phosphor
    static let warning  = PixelColor.warning
    static let danger   = NexusColor.danger

    // MARK: - Text

    static let textPrimary    = PixelColor.text
    static let textSecondary  = PixelColor.textSecondary
    static let textTertiary   = NexusColor.textTertiary
    static let textQuaternary = Color(red: 0.80, green: 0.78, blue: 0.76)

    // MARK: - Surface / separator

    static let separator              = NexusColor.separator
    static let cardBackground         = PixelColor.surface
    static let cardStroke             = PixelColor.border

    // MARK: - Legacy aliases

    static let backgroundPrimary          = background
    static let backgroundTertiary         = backgroundGroupedSecondary
    static let accentBlue                 = NexusColor.tier2
    static let accentBlueSoft             = NexusColor.tier2.opacity(0.12)
    static let accentIndigoMuted          = Color(red: 0.44, green: 0.34, blue: 0.90).opacity(0.12)
    static let accentCyan                 = Color(red: 0.13, green: 0.75, blue: 0.90)
    static let accentPurple               = Color(red: 0.60, green: 0.32, blue: 0.90)
    static let accentMagenta              = Color(red: 0.90, green: 0.25, blue: 0.65)
    static let accentGreen                = PixelColor.phosphor
    static let accentOrange               = PixelColor.phosphor
    static let accentRed                  = NexusColor.danger
    static let glassFill                  = PixelColor.surface
    static let glassStroke                = PixelColor.border
    static let glassHighlight             = Color.white.opacity(0.70)
    static let glowCyan                   = NexusColor.tier2.opacity(0.25)
    static let glowPurple                 = Color(red: 0.60, green: 0.32, blue: 0.90).opacity(0.25)

    // MARK: - Typography (rounded SF Pro)

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

    // MARK: - Corner radii (warm rounded aesthetic)

    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [PixelColor.background, NexusColor.surfaceHigh],
        startPoint: .top, endPoint: .bottom
    )

    static let spectrumGradient = LinearGradient(
        colors: [PixelColor.phosphor, PixelColor.warning],
        startPoint: .leading, endPoint: .trailing
    )

    static let cyanGradient = LinearGradient(
        colors: [NexusColor.tier2, NexusColor.tier2.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [Color(red: 0.60, green: 0.32, blue: 0.90),
                 Color(red: 0.60, green: 0.32, blue: 0.90).opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
