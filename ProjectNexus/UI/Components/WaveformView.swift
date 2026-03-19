import SwiftUI

/// Animated sine-wave waveform that breathes with the audio level.
struct WaveformView: View {
    let isActive: Bool
    let level: Float   // dB, typically -60...0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Normalise level to 0–1 drive, clamped to prevent runaway
                let drive = isActive
                    ? CGFloat(max(0.15, min(1.0, (level + 60) / 50)))
                    : 0.04

                let amplitude = drive * size.height * 0.36

                // Primary wave — warm orange when active, soft gray when inactive
                drawWave(context: context, size: size, time: time,
                         amplitude: amplitude, frequency: 2.5, phase: 0,
                         color: isActive
                            ? PixelColor.phosphor.opacity(0.80)
                            : PixelColor.textSecondary.opacity(0.30),
                         lineWidth: 2.5)

                // Secondary wave — slightly offset
                drawWave(context: context, size: size, time: time,
                         amplitude: amplitude * 0.65, frequency: 3.5, phase: 0.8,
                         color: isActive
                            ? PixelColor.phosphor.opacity(0.40)
                            : PixelColor.textSecondary.opacity(0.15),
                         lineWidth: 2)

                // Tertiary subtle wave
                drawWave(context: context, size: size, time: time,
                         amplitude: amplitude * 0.45, frequency: 5.0, phase: 1.6,
                         color: isActive
                            ? PixelColor.warning.opacity(0.20)
                            : Color.clear,
                         lineWidth: 1.5)
            }
        }
    }

    private func drawWave(
        context: GraphicsContext, size: CGSize,
        time: Double, amplitude: CGFloat,
        frequency: Double, phase: Double,
        color: Color, lineWidth: CGFloat
    ) {
        var path = Path()
        let midY = size.height / 2
        let steps = max(1, Int(size.width / 2))

        for i in 0...steps {
            let x = CGFloat(i) / CGFloat(steps) * size.width
            let nx = Double(x) / Double(size.width)
            let envelope = sin(nx * .pi)   // fade in/out at edges
            let y = midY + amplitude * CGFloat(sin(nx * frequency * .pi * 2 + time * 2.5 + phase) * envelope)

            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else       { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - SparklineView

/// Draws the last N RMS readings as a smooth line chart.
struct SparklineView: View {
    let values: [Float]     // expects dB values, e.g. from MetricsService.rmsHistory
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }

            let minVal: Float = -60
            let maxVal: Float = 0
            let range = maxVal - minVal

            var path = Path()
            for (i, v) in values.enumerated() {
                let x = CGFloat(i) / CGFloat(values.count - 1) * size.width
                let norm = CGFloat(max(0, min(1, (v - minVal) / range)))
                let y = size.height - norm * size.height * 0.9 - size.height * 0.05

                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }

            context.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
