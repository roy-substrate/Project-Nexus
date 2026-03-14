import SwiftUI

/// Design tokens for Nexus Shield.
///
/// All colours are **adaptive** — they use semantic UIKit/AppKit colour names so
/// that the UI automatically adjusts for light mode, dark mode, high-contrast
/// mode, and future appearance changes without any code changes.
enum NexusTheme {

    // MARK: - Adaptive background surfaces

    /// Primary page background (white in light, near-black in dark).
    static let background = Color(.systemBackground)
    /// Slightly off-page surface — use for inset / grouped sections.
    static let backgroundSecondary = Color(.secondarySystemBackground)
    /// Grouped list background (off-white in light, true black in dark).
    static let backgroundGrouped = Color(.systemGroupedBackground)
    /// Card surface inside grouped lists.
    static let backgroundGroupedSecondary = Color(.secondarySystemGroupedBackground)

    // MARK: - Brand / interactive

    /// Primary interactive colour.  Follows the system accent by default.
    static let accent = Color.blue
    /// Soft fill for highlighted backgrounds (e.g. selected row, active badge).
    static let accentFill = Color.blue.opacity(0.12)

    // MARK: - Tier colours

    /// Tier 1 — Acoustic (perceptual blue-teal)
    static let tier1 = Color(hue: 0.55, saturation: 0.78, brightness: 0.92)
    /// Tier 2 — Adversarial ML (rich indigo-violet)
    static let tier2 = Color(hue: 0.73, saturation: 0.70, brightness: 0.88)

    // MARK: - Semantic status

    static let positive = Color.green
    static let warning  = Color.orange
    static let danger   = Color.red

    // MARK: - Text (fully adaptive)

    static let textPrimary   = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary  = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)

    // MARK: - Surface / separator

    static let separator     = Color(.separator)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let cardStroke    = Color(.separator).opacity(0.5)

    // MARK: - Legacy aliases (used by existing components — mapped to adaptive equivalents)

    static let backgroundPrimary          = background
    static let backgroundTertiary         = backgroundGroupedSecondary
    static let accentBlue                 = Color.blue
    static let accentBlueSoft             = Color.blue.opacity(0.12)
    static let accentIndigoMuted          = Color.indigo.opacity(0.15)
    static let accentCyan                 = tier1
    static let accentPurple               = tier2
    static let accentMagenta              = Color.pink
    static let accentGreen                = Color.green
    static let accentOrange               = Color.orange
    static let accentRed                  = Color.red
    static let glassFill                  = Color(.secondarySystemGroupedBackground)
    static let glassStroke                = Color(.separator).opacity(0.4)
    static let glassHighlight             = Color(.systemBackground).opacity(0.8)
    static let glowCyan                   = tier1.opacity(0.22)
    static let glowPurple                 = tier2.opacity(0.22)

    // MARK: - Typography  (Dynamic Type — honours user's text size preference)

    /// Hero / onboarding headline
    static let displayFont   = Font.system(.largeTitle,   design: .default, weight: .bold)
    /// Screen titles, prominent labels
    static let titleFont     = Font.system(.title2,       design: .default, weight: .semibold)
    /// Section headings, card titles
    static let headlineFont  = Font.system(.headline,     design: .default, weight: .semibold)
    /// Main body copy
    static let bodyFont      = Font.system(.body,         design: .default, weight: .regular)
    /// Supporting descriptions
    static let subheadFont   = Font.system(.subheadline,  design: .default, weight: .regular)
    /// Labels, secondary metadata
    static let captionFont   = Font.system(.caption,      design: .default, weight: .medium)
    /// Numeric / data readouts
    static let monoFont      = Font.system(.body,         design: .monospaced, weight: .medium)
    static let monoSmall     = Font.system(.caption,      design: .monospaced, weight: .regular)

    // MARK: - Spacing  (8 pt grid)

    static let spacingXS:  CGFloat = 4
    static let spacingSM:  CGFloat = 8
    static let spacingMD:  CGFloat = 16
    static let spacingLG:  CGFloat = 24
    static let spacingXL:  CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner radii  (Apple's .continuous curve style)

    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 22
    static let radiusXL: CGFloat = 32

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
        startPoint: .top, endPoint: .bottom
    )

    static let spectrumGradient = LinearGradient(
        colors: [tier1, tier2],
        startPoint: .leading, endPoint: .trailing
    )

    static let cyanGradient = LinearGradient(
        colors: [tier1, tier1.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [tier2, tier2.opacity(0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
