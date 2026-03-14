import SwiftUI

struct ParticleFieldView: View {
    let particleCount: Int
    let isActive: Bool

    @State private var particles: [Particle] = []
    @State private var animationPhase: Double = 0

    init(particleCount: Int = 60, isActive: Bool = false) {
        self.particleCount = particleCount
        self.isActive = isActive
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let x = particle.position(at: time, in: size).x
                    let y = particle.position(at: time, in: size).y
                    let opacity = particle.opacity(at: time, isActive: isActive)
                    let radius = particle.radius * (isActive ? 1.3 : 1.0)

                    let color: Color = particle.useCyan
                        ? NexusTheme.accentCyan.opacity(opacity)
                        : NexusTheme.accentPurple.opacity(opacity)

                    let rect = CGRect(
                        x: x - radius, y: y - radius,
                        width: radius * 2, height: radius * 2
                    )
                    context.fill(Circle().path(in: rect), with: .color(color))

                    if isActive && particle.radius > 1.5 {
                        let glowRect = CGRect(
                            x: x - radius * 3, y: y - radius * 3,
                            width: radius * 6, height: radius * 6
                        )
                        context.fill(
                            Circle().path(in: glowRect),
                            with: .color(color.opacity(opacity * 0.15))
                        )
                    }
                }
            }
        }
        .onAppear {
            particles = (0..<particleCount).map { _ in Particle.random() }
        }
    }
}

private struct Particle {
    let baseX: Double
    let baseY: Double
    let driftSpeedX: Double
    let driftSpeedY: Double
    let radius: CGFloat
    let phaseOffset: Double
    let flickerSpeed: Double
    let useCyan: Bool

    func position(at time: Double, in size: CGSize) -> CGPoint {
        let x = (baseX + sin(time * driftSpeedX + phaseOffset) * 0.05)
            .truncatingRemainder(dividingBy: 1.0)
        let y = (baseY + cos(time * driftSpeedY + phaseOffset * 1.3) * 0.04)
            .truncatingRemainder(dividingBy: 1.0)
        return CGPoint(
            x: abs(x) * size.width,
            y: abs(y) * size.height
        )
    }

    func opacity(at time: Double, isActive: Bool) -> Double {
        let base = 0.15 + sin(time * flickerSpeed + phaseOffset) * 0.1
        return isActive ? min(base + 0.15, 0.5) : base
    }

    static func random() -> Particle {
        Particle(
            baseX: Double.random(in: 0...1),
            baseY: Double.random(in: 0...1),
            driftSpeedX: Double.random(in: 0.05...0.2),
            driftSpeedY: Double.random(in: 0.03...0.15),
            radius: CGFloat.random(in: 0.5...2.5),
            phaseOffset: Double.random(in: 0...(2 * .pi)),
            flickerSpeed: Double.random(in: 0.3...1.2),
            useCyan: Bool.random()
        )
    }
}
