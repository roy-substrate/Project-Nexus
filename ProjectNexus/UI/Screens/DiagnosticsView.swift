import SwiftUI

struct DiagnosticsView: View {
    let metricsService: MetricsService
    let isActive: Bool

    var body: some View {
        ZStack {
            NexusTheme.backgroundPrimary.ignoresSafeArea()
            NexusTheme.backgroundGradient.ignoresSafeArea().opacity(0.4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: NexusTheme.spacingLG) {
                    headerSection

                    spectrumSection
                    metricsGrid
                    engineStatusSection
                }
                .padding(.horizontal, NexusTheme.spacingMD)
                .padding(.bottom, 100)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("DIAGNOSTICS")
                .font(NexusTheme.captionFont)
                .foregroundStyle(NexusTheme.textTertiary)
                .tracking(2)

            Spacer()

            if isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(NexusTheme.accentGreen)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(NexusTheme.monoSmall)
                        .foregroundStyle(NexusTheme.accentGreen)
                }
            }
        }
        .padding(.top, NexusTheme.spacingSM)
    }

    private var spectrumSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Text("SPECTRUM ANALYSIS")
                        .font(NexusTheme.captionFont)
                        .foregroundStyle(NexusTheme.textTertiary)
                        .tracking(1)

                    Spacer()

                    legendItem(color: NexusTheme.accentCyan, label: "Input")
                    legendItem(color: NexusTheme.accentPurple, label: "Perturbation")
                    legendItem(color: NexusTheme.accentOrange, label: "Masking")
                }

                SpectrumVisualizerView(
                    spectrumData: metricsService.currentMetrics.spectrumData,
                    maskingThreshold: metricsService.currentMetrics.maskingThreshold,
                    perturbationSpectrum: metricsService.currentMetrics.perturbationSpectrum,
                    isActive: isActive
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: NexusTheme.radiusSM))

                // Frequency axis labels
                HStack {
                    Text("100Hz")
                    Spacer()
                    Text("1kHz")
                    Spacer()
                    Text("4kHz")
                    Spacer()
                    Text("20kHz")
                }
                .font(NexusTheme.monoSmall)
                .foregroundStyle(NexusTheme.textTertiary)
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: NexusTheme.spacingSM),
            GridItem(.flexible(), spacing: NexusTheme.spacingSM)
        ], spacing: NexusTheme.spacingSM) {
            metricTile(
                title: "LATENCY",
                value: String(format: "%.1f", metricsService.currentMetrics.latencyMs),
                unit: "ms",
                color: metricsService.currentMetrics.latencyMs < 30
                    ? NexusTheme.accentGreen : NexusTheme.accentOrange,
                icon: "timer"
            )

            metricTile(
                title: "RMS LEVEL",
                value: String(format: "%.1f", metricsService.currentMetrics.rmsLevel),
                unit: "dB",
                color: NexusTheme.accentCyan,
                icon: "waveform"
            )

            metricTile(
                title: "PEAK LEVEL",
                value: String(format: "%.1f", metricsService.currentMetrics.peakLevel),
                unit: "dB",
                color: metricsService.currentMetrics.peakLevel > -3
                    ? NexusTheme.accentRed : NexusTheme.accentCyan,
                icon: "chart.line.uptrend.xyaxis"
            )

            metricTile(
                title: "UNDERRUNS",
                value: "\(metricsService.currentMetrics.bufferUnderruns)",
                unit: "",
                color: metricsService.currentMetrics.bufferUnderruns > 0
                    ? NexusTheme.accentRed : NexusTheme.accentGreen,
                icon: "exclamationmark.triangle"
            )

            metricTile(
                title: "CPU",
                value: String(format: "%.1f", metricsService.currentMetrics.cpuUsage),
                unit: "%",
                color: metricsService.currentMetrics.cpuUsage > 70
                    ? NexusTheme.accentRed
                    : metricsService.currentMetrics.cpuUsage > 40
                        ? NexusTheme.accentOrange
                        : NexusTheme.accentGreen,
                icon: "cpu"
            )
        }
    }

    private var engineStatusSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                Text("ENGINE STATUS")
                    .font(NexusTheme.captionFont)
                    .foregroundStyle(NexusTheme.textTertiary)
                    .tracking(1)

                statusRow(
                    "Audio Engine",
                    value: metricsService.currentMetrics.isEngineRunning ? "Running" : "Stopped",
                    color: metricsService.currentMetrics.isEngineRunning ? NexusTheme.accentGreen : NexusTheme.textTertiary
                )

                statusRow("Sample Rate", value: liveSampleRate, color: NexusTheme.textPrimary)

                statusRow("Buffer Size", value: liveBufferSize, color: NexusTheme.textPrimary)

                statusRow("Format", value: "Float32 Mono", color: NexusTheme.textPrimary)
            }
        }
    }

    // MARK: - Live engine values from AVAudioSession

    private var liveSampleRate: String {
        let rate = AudioSessionConfigurator.shared.sampleRate
        guard rate > 0 else { return "—" }
        let kHz = rate / 1000
        return kHz == kHz.rounded() ? "\(Int(rate)) Hz" : String(format: "%.1f kHz", kHz)
    }

    private var liveBufferSize: String {
        let configurator = AudioSessionConfigurator.shared
        let rate = configurator.sampleRate
        let duration = configurator.ioBufferDuration
        guard rate > 0 && duration > 0 else { return "—" }
        let frames = Int((duration * rate).rounded())
        return "\(frames) samples"
    }

    private func metricTile(title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        GlassCard(tint: color) {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color)
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(NexusTheme.textPrimary)

                    Text(unit)
                        .font(NexusTheme.monoSmall)
                        .foregroundStyle(NexusTheme.textTertiary)
                }

                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(NexusTheme.textTertiary)
                    .tracking(1)
            }
        }
    }

    private func statusRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(NexusTheme.bodyFont)
                .foregroundStyle(NexusTheme.textSecondary)
            Spacer()
            Text(value)
                .font(NexusTheme.monoFont)
                .foregroundStyle(color)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label).font(.system(size: 9)).foregroundStyle(NexusTheme.textTertiary)
        }
    }
}
