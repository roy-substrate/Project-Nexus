import SwiftUI

struct SpectrumVisualizerView: View {
    let spectrumData: [Float]
    let maskingThreshold: [Float]
    let perturbationSpectrum: [Float]
    let isActive: Bool

    @State private var animatedSpectrum: [Float] = []

    private let barCount = 64
    private let smoothingFactor: Float = 0.3

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(barCount)
            let height = geometry.size.height

            Canvas { context, size in
                let downsampled = downsample(spectrumData, to: barCount)
                let maskDownsampled = downsample(maskingThreshold, to: barCount)
                let pertDownsampled = downsample(perturbationSpectrum, to: barCount)

                // Draw perturbation spectrum (background layer)
                if isActive {
                    for i in 0..<barCount {
                        let normalized = CGFloat(normalizeDB(pertDownsampled[i]))
                        let barHeight = max(normalized * height * 0.8, 1)
                        let x = CGFloat(i) * barWidth
                        let y = height - barHeight

                        let rect = CGRect(x: x + 1, y: y, width: barWidth - 2, height: barHeight)
                        let t = CGFloat(i) / CGFloat(barCount)
                        let color = interpolateColor(t: t, alpha: 0.15)
                        context.fill(
                            RoundedRectangle(cornerRadius: 1).path(in: rect),
                            with: .color(color)
                        )
                    }
                }

                // Draw main spectrum bars
                for i in 0..<barCount {
                    let normalized = CGFloat(normalizeDB(downsampled[i]))
                    let barHeight = max(normalized * height * 0.8, 2)
                    let x = CGFloat(i) * barWidth
                    let y = height - barHeight

                    let rect = CGRect(x: x + 1, y: y, width: barWidth - 2, height: barHeight)
                    let t = CGFloat(i) / CGFloat(barCount)
                    let color = interpolateColor(t: t, alpha: isActive ? 0.7 : 0.35)
                    context.fill(
                        RoundedRectangle(cornerRadius: 1).path(in: rect),
                        with: .color(color)
                    )

                    // Top highlight
                    let capRect = CGRect(x: x + 1, y: y, width: barWidth - 2, height: 2)
                    context.fill(
                        Rectangle().path(in: capRect),
                        with: .color(color.opacity(1.0))
                    )
                }

                // Draw masking threshold line
                if isActive {
                    var path = Path()
                    for i in 0..<barCount {
                        let normalized = CGFloat(normalizeDB(maskDownsampled[i]))
                        let x = CGFloat(i) * barWidth + barWidth / 2
                        let y = height - (normalized * height * 0.8)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    context.stroke(
                        path,
                        with: .color(NexusTheme.accentOrange.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                }
            }
        }
        .drawingGroup()
    }

    private func downsample(_ data: [Float], to count: Int) -> [Float] {
        guard !data.isEmpty else { return [Float](repeating: -60, count: count) }
        let binSize = max(1, data.count / count)
        return (0..<count).map { i in
            let start = i * binSize
            let end = min(start + binSize, data.count)
            guard start < end else { return -60.0 as Float }
            let slice = data[start..<end]
            return slice.max() ?? -60
        }
    }

    private func normalizeDB(_ value: Float) -> Float {
        let clamped = max(-60, min(0, value))
        return (clamped + 60) / 60
    }

    private func interpolateColor(t: CGFloat, alpha: CGFloat) -> Color {
        if t < 0.5 {
            return NexusTheme.accentCyan.opacity(alpha)
        } else {
            return NexusTheme.accentPurple.opacity(alpha)
        }
    }
}
