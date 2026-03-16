import SwiftUI

/// Design tokens for Nexus Shield.
///
/// All new work should use `NexusColor`, `NexusFont`, and `NexusSurface` from
/// `NexusDesignSystem.swift`. The properties below are compatibility aliases
/// that forward to the new token system — existing code continues to compile
/// without modification.
enum NexusTheme {

    // MARK: - Background surfaces (forward to NexusColor)

    static let background                  = NexusColor.background
    static let backgroundSecondary         = NexusColor.surface
    static let backgroundGrouped           = NexusColor.background
    static let backgroundGroupedSecondary  = NexusColor.surface

    // MARK: - Brand / interactive

    static let accent     = NexusColor.accent
    static let accentFill = NexusColor.accentFill

    // MARK: - Tier colours

    static let tier1 = NexusColor.tier1
    static let tier2 = NexusColor.tier2

    // MARK: - Semantic status

    static let positive = NexusColor.accentEmerald
    static let warning  = NexusColor.warning
    static let danger   = NexusColor.danger

    // MARK: - Text

    static let textPrimary    = NexusColor.textPrimary
    static let textSecondary  = NexusColor.textSecondary
    static let textTertiary   = NexusColor.textTertiary
    static let textQuaternary = NexusColor.textTertiary

    // MARK: - Surface / separator

    static let separator              = NexusColor.separator
    static let cardBackground         = NexusColor.surface
    static let cardStroke             = NexusColor.cardBorder

    // MARK: - Legacy aliases

    static let backgroundPrimary          = background
    static let backgroundTertiary         = backgroundGroupedSecondary
    static let accentBlue                 = NexusColor.accent
    static let accentBlueSoft             = NexusColor.accentFill
    static let accentIndigoMuted          = NexusColor.accent.opacity(0.15)
    static let accentCyan                 = NexusColor.tier1
    static let accentPurple               = NexusColor.tier2
    static let accentMagenta              = Color.pink
    static let accentGreen                = NexusColor.accentEmerald
    static let accentOrange               = NexusColor.warning
    static let accentRed                  = NexusColor.danger
    static let glassFill                  = NexusColor.surface
    static let glassStroke                = NexusColor.cardBorder
    static let glassHighlight             = NexusColor.surfaceHigh
    static let glowCyan                   = NexusColor.tier1.opacity(0.22)
    static let glowPurple                 = NexusColor.tier2.opacity(0.22)

    // MARK: - Typography (legacy aliases — prefer NexusFont)

    static let displayFont   = Font.system(.largeTitle, design: .default, weight: .bold)
    static let titleFont     = Font.system(.title2, design: .default, weight: .semibold)
    static let headlineFont  = Font.system(.headline, design: .default, weight: .semibold)
    static let bodyFont      = Font.system(.body, design: .default, weight: .regular)
    static let subheadFont   = Font.system(.subheadline, design: .default, weight: .regular)
    static let captionFont   = Font.system(.caption, design: .default, weight: .medium)
    static let monoFont      = Font.system(.body, design: .monospaced, weight: .medium)
    static let monoSmall     = Font.system(.caption, design: .monospaced, weight: .regular)

    // MARK: - Spacing  (8 pt grid)

    static let spacingXS:  CGFloat = 4
    static let spacingSM:  CGFloat = 8
    static let spacingMD:  CGFloat = 16
    static let spacingLG:  CGFloat = 24
    static let spacingXL:  CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner radii

    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 20
    static let radiusLG: CGFloat = 24
    static let radiusXL: CGFloat = 32

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [NexusColor.background, NexusColor.surface],
        startPoint: .top, endPoint: .bottom
    )

    static let spectrumGradient = LinearGradient(
        colors: [NexusColor.tier1, NexusColor.tier2],
        startPoint: .leading, endPoint: .trailing
    )

    static let cyanGradient = LinearGradient(
        colors: [NexusColor.tier1, NexusColor.tier1.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [NexusColor.tier2, NexusColor.tier2.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
