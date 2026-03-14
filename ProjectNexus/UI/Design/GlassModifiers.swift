import SwiftUI

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = NexusTheme.radiusMD
    var padding: CGFloat = NexusTheme.spacingMD

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(NexusTheme.glassFill)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        NexusTheme.glassHighlight,
                                        NexusTheme.glassStroke,
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.15), radius: radius * 2, x: 0, y: 0)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.08),
                        .clear
                    ],
                    startPoint: .init(x: phase - 0.3, y: phase - 0.3),
                    endPoint: .init(x: phase + 0.3, y: phase + 0.3)
                )
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = NexusTheme.radiusMD, padding: CGFloat = NexusTheme.spacingMD) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    func glow(color: Color, radius: CGFloat = 20) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func nexusBackground() -> some View {
        self.background {
            NexusTheme.backgroundPrimary
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}
