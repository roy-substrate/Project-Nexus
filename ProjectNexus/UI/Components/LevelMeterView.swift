import SwiftUI

struct LevelMeterView: View {
    let level: Float
    let peak: Float

    private let segmentCount = 20
    private let minDB: Float = -60
    private let maxDB: Float = 0

    var body: some View {
        GeometryReader { geometry in
            let normalizedLevel = CGFloat((level - minDB) / (maxDB - minDB))
            let normalizedPeak = CGFloat((peak - minDB) / (maxDB - minDB))
            let segmentWidth = geometry.size.width / CGFloat(segmentCount)

            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { i in
                    let threshold = CGFloat(i) / CGFloat(segmentCount)
                    let isLit = normalizedLevel > threshold
                    let isPeak = abs(normalizedPeak - threshold) < (1.0 / CGFloat(segmentCount))

                    RoundedRectangle(cornerRadius: 1)
                        .fill(segmentColor(for: i, isLit: isLit, isPeak: isPeak))
                        .frame(height: geometry.size.height)
                }
            }
        }
        .frame(height: 6)
    }

    private func segmentColor(for index: Int, isLit: Bool, isPeak: Bool) -> Color {
        let position = Float(index) / Float(segmentCount)
        let baseColor: Color
        if position < 0.6 {
            baseColor = NexusTheme.accentCyan
        } else if position < 0.8 {
            baseColor = NexusTheme.accentOrange
        } else {
            baseColor = NexusTheme.accentRed
        }

        if isPeak {
            return baseColor
        } else if isLit {
            return baseColor.opacity(0.7)
        } else {
            return baseColor.opacity(0.1)
        }
    }
}
