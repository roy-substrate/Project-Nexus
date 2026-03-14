import SwiftUI

struct WaveformView: View {
    let isActive: Bool
    let level: Float

    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = size.width
                let height = size.height
                let midY = height / 2

                let amplitude = isActive
                    ? CGFloat(max(0.15, min(1.0, (level + 60) / 50))) * height * 0.35
                    : height * 0.04

                // Draw three layered waveforms
                drawWave(
                    context: context, size: size, time: time,
                    amplitude: amplitude, frequency: 2.5, phase: 0,
                    color: NexusTheme.accentCyan.opacity(isActive ? 0.4 : 0.12),
                    lineWidth: 2
                )
                drawWave(
                    context: context, size: size, time: time,
                    amplitude: amplitude * 0.7, frequency: 3.5, phase: 0.8,
                    color: NexusTheme.accentPurple.opacity(isActive ? 0.35 : 0.08),
                    lineWidth: 1.5
                )
                drawWave(
                    context: context, size: size, time: time,
                    amplitude: amplitude * 0.5, frequency: 5.0, phase: 1.6,
                    color: NexusTheme.accentCyan.opacity(isActive ? 0.25 : 0.06),
                    lineWidth: 1
                )
            }
        }
    }

    private func drawWave(
        context: GraphicsContext, size: CGSize, time: Double,
        amplitude: CGFloat, frequency: Double, phase: Double,
        color: Color, lineWidth: CGFloat
    ) {
        var path = Path()
        let midY = size.height / 2
        let steps = Int(size.width / 2)

        for i in 0...steps {
            let x = CGFloat(i) / CGFloat(steps) * size.width
            let normalizedX = Double(x) / Double(size.width)
            let y = midY + amplitude * sin(normalizedX * frequency * .pi * 2 + time * 2.5 + phase)
                * CGFloat(sin(normalizedX * .pi))

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}
