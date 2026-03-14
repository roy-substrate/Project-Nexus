import SwiftUI

enum NexusTheme {
    // MARK: - Colors

    static let backgroundPrimary = Color(red: 0.03, green: 0.03, blue: 0.08)
    static let backgroundSecondary = Color(red: 0.06, green: 0.05, blue: 0.14)
    static let backgroundTertiary = Color(red: 0.04, green: 0.08, blue: 0.12)

    static let accentCyan = Color(red: 0.0, green: 0.85, blue: 0.95)
    static let accentPurple = Color(red: 0.58, green: 0.34, blue: 0.98)
    static let accentMagenta = Color(red: 0.85, green: 0.2, blue: 0.65)
    static let accentGreen = Color(red: 0.18, green: 0.9, blue: 0.55)
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.16)
    static let accentRed = Color(red: 0.95, green: 0.22, blue: 0.32)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    static let glassStroke = Color.white.opacity(0.12)
    static let glassFill = Color.white.opacity(0.06)
    static let glassHighlight = Color.white.opacity(0.15)

    // MARK: - Gradients

    static let backgroundGradient = MeshGradient(
        width: 3, height: 3,
        points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ],
        colors: [
            backgroundPrimary, backgroundSecondary, backgroundPrimary,
            backgroundTertiary, backgroundPrimary, backgroundSecondary,
            backgroundSecondary, backgroundTertiary, backgroundPrimary
        ]
    )

    static let cyanGradient = LinearGradient(
        colors: [accentCyan, accentCyan.opacity(0.4)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [accentPurple, accentMagenta.opacity(0.6)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let spectrumGradient = LinearGradient(
        colors: [accentCyan, accentPurple, accentMagenta],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Typography

    static let displayFont = Font.system(size: 28, weight: .bold, design: .default)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .default)
    static let monoFont = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Radii

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 14
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // MARK: - Shadows

    static let glowCyan = Color(red: 0.0, green: 0.85, blue: 0.95).opacity(0.4)
    static let glowPurple = Color(red: 0.58, green: 0.34, blue: 0.98).opacity(0.4)
}
