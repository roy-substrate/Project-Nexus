import SwiftUI

struct PulseRingView: View {
    let isActive: Bool
    let color: Color

    @State private var ring1Scale: CGFloat = 0.8
    @State private var ring2Scale: CGFloat = 0.8
    @State private var ring3Scale: CGFloat = 0.8
    @State private var ring1Opacity: Double = 0
    @State private var ring2Opacity: Double = 0
    @State private var ring3Opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(ring3Opacity), lineWidth: 1)
                .scaleEffect(ring3Scale)

            Circle()
                .stroke(color.opacity(ring2Opacity), lineWidth: 1.5)
                .scaleEffect(ring2Scale)

            Circle()
                .stroke(color.opacity(ring1Opacity), lineWidth: 2)
                .scaleEffect(ring1Scale)
        }
        .onChange(of: isActive) { _, active in
            if active {
                startPulsing()
            } else {
                stopPulsing()
            }
        }
        .onAppear {
            if isActive { startPulsing() }
        }
    }

    private func startPulsing() {
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            ring1Scale = 1.6
            ring1Opacity = 0
        }
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false).delay(0.6)) {
            ring2Scale = 1.6
            ring2Opacity = 0
        }
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false).delay(1.2)) {
            ring3Scale = 1.6
            ring3Opacity = 0
        }

        ring1Opacity = 0.5
        ring2Opacity = 0.4
        ring3Opacity = 0.3
    }

    private func stopPulsing() {
        withAnimation(.easeInOut(duration: 0.5)) {
            ring1Scale = 0.8
            ring2Scale = 0.8
            ring3Scale = 0.8
            ring1Opacity = 0
            ring2Opacity = 0
            ring3Opacity = 0
        }
    }
}
