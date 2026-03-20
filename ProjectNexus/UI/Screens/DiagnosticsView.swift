import SwiftUI

struct DiagnosticsView: View {
    let metricsService: MetricsService
    let isActive: Bool
    var asrService: ASREffectivenessService? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    spectrumSection
                    metricsGrid
                    if asrService != nil { asrSection }
                    engineSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(NexusColor.background.ignoresSafeArea())
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("Live", systemImage: "circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.green)
                            .labelStyle(TrailingIconLabelStyle())
                    }
                }
            }
        }
    }

    // MARK: - Spectrum

    private var spectrumSection: some View {
        diagCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("Spectrum")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    legendDot(color: NexusTheme.tier1, label: "Input")
                    legendDot(color: NexusTheme.tier2, label: "Perturbation")
                    legendDot(color: .orange, label: "Masking")
                }

                SpectrumVisualizerView(
                    spectrumData: metricsService.currentMetrics.spectrumData,
                    maskingThreshold: metricsService.currentMetrics.maskingThreshold,
                    perturbationSpectrum: metricsService.currentMetrics.perturbationSpectrum,
                    isActive: isActive
                )
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Text("100 Hz").frame(maxWidth: .infinity, alignment: .leading)
                    Text("1 kHz").frame(maxWidth: .infinity, alignment: .center)
                    Text("4 kHz").frame(maxWidth: .infinity, alignment: .center)
                    Text("20 kHz").frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(PixelColor.textSecondary)
            }
        }
    }

    // MARK: - Metric tiles

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            metricTile("Latency",
                       value: String(format: "%.1f", metricsService.currentMetrics.latencyMs),
                       unit: "ms",
                       icon: "timer",
                       accent: metricsService.currentMetrics.latencyMs < 30 ? .green : .orange)

            metricTile("RMS Level",
                       value: String(format: "%.1f", metricsService.currentMetrics.rmsLevel),
                       unit: "dB",
                       icon: "waveform",
                       accent: NexusTheme.tier1)

            metricTile("Peak Level",
                       value: String(format: "%.1f", metricsService.currentMetrics.peakLevel),
                       unit: "dB",
                       icon: "chart.line.uptrend.xyaxis",
                       accent: metricsService.currentMetrics.peakLevel > -3 ? .red : NexusTheme.tier1)

            metricTile("Underruns",
                       value: "\(metricsService.currentMetrics.bufferUnderruns)",
                       unit: "",
                       icon: "exclamationmark.triangle",
                       accent: metricsService.currentMetrics.bufferUnderruns > 0 ? .red : .green)

            metricTile("CPU Usage",
                       value: String(format: "%.1f", metricsService.currentMetrics.cpuUsage),
                       unit: "%",
                       icon: "cpu",
                       accent: metricsService.currentMetrics.cpuUsage > 70 ? .red
                             : metricsService.currentMetrics.cpuUsage > 40 ? .orange : .green)
        }
    }

    private func metricTile(_ title: String, value: String, unit: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(accent)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(PixelColor.text)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(PixelColor.textSecondary)
            }

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PixelColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PixelColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(accent.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - ASR Jamming

    private var asrSection: some View {
        diagCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("ASR Jamming")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    if asrService?.isMeasuring == true {
                        Label("Measuring", systemImage: "circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.green)
                            .labelStyle(TrailingIconLabelStyle())
                    }
                }

                if let asr = asrService {
                    let score = asr.effectivenessScore

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", score * 100))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundStyle(jamColor(score))
                            .contentTransition(.numericText())
                        Text("%")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(jamLabel(score))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(jamColor(score))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(jamColor(score).opacity(0.1)))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(PixelColor.border.opacity(0.4)).frame(height: 5)
                            Capsule()
                                .fill(jamColor(score))
                                .frame(width: geo.size.width * CGFloat(score), height: 5)
                                .animation(.spring(response: 0.5), value: score)
                        }
                    }
                    .frame(height: 5)

                    Text("Word recognition rate degraded by the perturbation engine vs. baseline.")
                        .font(.system(size: 12))
                        .foregroundStyle(PixelColor.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
    }

    private func jamColor(_ s: Float) -> Color {
        // High jam score = excellent protection = green. Low = poor = red.
        s < 0.33 ? .red : s < 0.66 ? .orange : .green
    }
    private func jamLabel(_ s: Float) -> String {
        s < 0.33 ? "Low" : s < 0.66 ? "Moderate" : "High"
    }

    // MARK: - Engine status

    private var engineSection: some View {
        diagCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Engine")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.bottom, 14)

                VStack(spacing: 0) {
                    engineRow("Status",
                              value: metricsService.currentMetrics.isEngineRunning ? "Running" : "Stopped",
                              color: metricsService.currentMetrics.isEngineRunning ? .green : .secondary)
                    Divider().padding(.leading, 0)
                    engineRow("Sample rate", value: liveSampleRate, color: .primary)
                    Divider()
                    engineRow("Buffer size",  value: liveBufferSize, color: .primary)
                    Divider()
                    engineRow("Format", value: "Float32 Mono", color: .primary)
                }
            }
        }
    }

    private func engineRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(PixelColor.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(color == .primary ? PixelColor.text : color)
        }
        .padding(.vertical, 11)
    }

    // MARK: - Helpers

    private var liveSampleRate: String {
        let r = AudioSessionConfigurator.shared.sampleRate
        guard r > 0 else { return "—" }
        return "\(Int(r)) Hz"
    }

    private var liveBufferSize: String {
        let c = AudioSessionConfigurator.shared
        guard c.sampleRate > 0, c.ioBufferDuration > 0 else { return "—" }
        return "\(Int((c.ioBufferDuration * c.sampleRate).rounded())) samples"
    }

    @ViewBuilder
    private func diagCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PixelColor.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(PixelColor.border.opacity(0.45), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10)).foregroundStyle(PixelColor.textSecondary)
        }
    }
}

// MARK: - Trailing icon label style

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.system(size: 7))
            configuration.title
        }
    }
}
