import SwiftUI

/// Real-time spectrum analyser with 64 frequency bars.
/// Colours adapt to both light and dark mode via semantic system colours.
struct SpectrumVisualizerView: View {
    let spectrumData: [Float]
    let maskingThreshold: [Float]
    let perturbationSpectrum: [Float]
    let isActive: Bool

    private let barCount = 64

    var body: some View {
        GeometryReader { geo in
            let bw = geo.size.width / CGFloat(barCount)
            let h  = geo.size.height

            Canvas { context, size in
                let spectrum = downsample(spectrumData,        to: barCount)
                let masking  = downsample(maskingThreshold,     to: barCount)
                let pert     = downsample(perturbationSpectrum, to: barCount)

                // ── Background layer: perturbation spectrum ──────────────────
                if isActive {
                    for i in 0..<barCount {
                        let norm = CGFloat(normalizeDB(pert[i]))
                        let bh   = max(norm * h * 0.8, 1)
                        let rect = CGRect(x: CGFloat(i) * bw + 1, y: h - bh,
                                          width: bw - 2, height: bh)
                        context.fill(
                            RoundedRectangle(cornerRadius: 1).path(in: rect),
                            with: .color(barColor(index: i, alpha: 0.14))
                        )
                    }
                }

                // ── Main spectrum bars ───────────────────────────────────────
                for i in 0..<barCount {
                    let norm = CGFloat(normalizeDB(spectrum[i]))
                    let bh   = max(norm * h * 0.8, 2)
                    let rect = CGRect(x: CGFloat(i) * bw + 1, y: h - bh,
                                      width: bw - 2, height: bh)
                    context.fill(
                        RoundedRectangle(cornerRadius: 1).path(in: rect),
                        with: .color(barColor(index: i, alpha: isActive ? 0.75 : 0.30))
                    )
                    // Peak cap
                    let cap = CGRect(x: CGFloat(i) * bw + 1, y: h - bh, width: bw - 2, height: 2)
                    context.fill(
                        Rectangle().path(in: cap),
                        with: .color(barColor(index: i, alpha: isActive ? 1.0 : 0.45))
                    )
                }

                // ── Masking threshold line ───────────────────────────────────
                if isActive {
                    var path = Path()
                    for i in 0..<barCount {
                        let norm = CGFloat(normalizeDB(masking[i]))
                        let x = CGFloat(i) * bw + bw / 2
                        let y = h - norm * h * 0.8
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else       { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    context.stroke(
                        path,
                        with: .color(Color.orange.opacity(0.55)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                }
            }
        }
        .drawingGroup()
    }

    // MARK: - Helpers

    private func downsample(_ data: [Float], to count: Int) -> [Float] {
        guard !data.isEmpty else { return [Float](repeating: -60, count: count) }
        let binSize = max(1, data.count / count)
        return (0..<count).map { i in
            let start = i * binSize
            let end   = min(start + binSize, data.count)
            return start < end ? (data[start..<end].max() ?? -60) : -60
        }
    }

    private func normalizeDB(_ value: Float) -> Float {
        (max(-60, min(0, value)) + 60) / 60
    }

    /// Returns a colour that transitions from blue (low freq) to indigo (high freq).
    private func barColor(index: Int, alpha: CGFloat) -> Color {
        let t = CGFloat(index) / CGFloat(barCount)
        // Lerp between system blue and indigo
        return t < 0.5
            ? Color(hue: 0.60, saturation: 0.75, brightness: 0.90).opacity(alpha)
            : Color(hue: 0.72, saturation: 0.65, brightness: 0.85).opacity(alpha)
    }
}
