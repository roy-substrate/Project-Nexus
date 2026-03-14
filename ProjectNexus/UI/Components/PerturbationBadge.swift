import SwiftUI

struct PerturbationBadge: View {
    let technique: PerturbationTechnique
    let isActive: Bool

    private var color: Color {
        technique.tier == .tier1 ? NexusTheme.accentCyan : NexusTheme.accentPurple
    }

    var body: some View {
        HStack(spacing: NexusTheme.spacingXS) {
            Image(systemName: technique.iconName)
                .font(.system(size: 10, weight: .semibold))

            Text(technique.rawValue)
                .font(NexusTheme.monoSmall)
        }
        .foregroundStyle(isActive ? color : NexusTheme.textTertiary)
        .padding(.horizontal, NexusTheme.spacingSM)
        .padding(.vertical, NexusTheme.spacingXS)
        .background {
            Capsule()
                .fill(isActive ? color.opacity(0.12) : NexusTheme.glassFill)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isActive ? color.opacity(0.3) : NexusTheme.glassStroke,
                            lineWidth: 0.5
                        )
                }
        }
    }
}
