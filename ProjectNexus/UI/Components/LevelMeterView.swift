import SwiftUI

/// Segmented horizontal level meter showing RMS level and peak hold.
/// Transitions from green → orange → red with adaptive opacity.
struct LevelMeterView: View {
    let level: Float   // dB, -60...0
    let peak: Float    // dB, -60...0

    private let segmentCount = 20
    private let minDB: Float = -60
    private let maxDB: Float = 0

    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { i in
                    let threshold = Float(i) / Float(segmentCount)
                    let normLevel = (level - minDB) / (maxDB - minDB)
                    let normPeak  = (peak  - minDB) / (maxDB - minDB)
                    let isLit  = normLevel > threshold
                    let isPeak = abs(normPeak - threshold) < (1.0 / Float(segmentCount))

                    RoundedRectangle(cornerRadius: 1)
                        .fill(segmentColor(position: threshold, isLit: isLit, isPeak: isPeak))
                }
            }
        }
        .frame(height: 6)
    }

    private func segmentColor(position: Float, isLit: Bool, isPeak: Bool) -> Color {
        let base: Color
        if position < 0.60 {
            base = .green
        } else if position < 0.80 {
            base = .orange
        } else {
            base = .red
        }

        if isPeak  { return base }
        if isLit   { return base.opacity(0.75) }
        return base.opacity(0.12)
    }
}
