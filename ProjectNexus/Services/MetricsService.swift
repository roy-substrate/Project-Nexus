import Foundation
import Accelerate

/// Smooths raw `AudioMetrics` from the audio engine with exponential moving averages
/// and maintains a short history buffer suitable for sparkline rendering.
@MainActor
@Observable
final class MetricsService {

    // MARK: - Published state

    var currentMetrics: AudioMetrics = .empty

    /// Last `historyCapacity` smoothed RMS readings, oldest first.
    /// Suitable for rendering a rolling sparkline in the UI.
    private(set) var rmsHistory: [Float]

    // MARK: - Configuration

    /// Number of RMS samples kept in the history ring buffer (~2 s at 30 Hz).
    private let historyCapacity = 60

    /// EMA coefficient for scalar metrics (RMS, peak, latency).
    /// Higher = faster response, more noise.  0.25 ≈ ~4-sample lag at 30 Hz.
    private let scalarAlpha: Float = 0.25

    /// EMA coefficient for spectrum bins.
    /// Lower = smoother visual, slightly lagging.
    private let spectrumAlpha: Float = 0.12

    // MARK: - Private EMA state

    private var smoothedRMS: Float = -60
    private var smoothedPeak: Float = -60
    private var smoothedLatency: Double = 0
    private var smoothedSpectrum: [Float]
    private var smoothedMasking: [Float]
    private var smoothedPerturbation: [Float]

    private var historyIndex = 0

    // MARK: - Init

    init() {
        rmsHistory       = [Float](repeating: -60, count: historyCapacity)
        smoothedSpectrum     = [Float](repeating: -60, count: 256)
        smoothedMasking      = [Float](repeating: -60, count: 256)
        smoothedPerturbation = [Float](repeating: 0,   count: 256)
    }

    // MARK: - Control

    func startMonitoring(perturbationService: PerturbationService) {
        perturbationService.onMetricsUpdate = { [weak self] metrics in
            self?.process(metrics)
        }
    }

    func stopMonitoring() {
        // Reset smoothed state so stale values don't bleed into the next session.
        smoothedRMS     = -60
        smoothedPeak    = -60
        smoothedLatency = 0
        smoothedSpectrum     = [Float](repeating: -60, count: 256)
        smoothedMasking      = [Float](repeating: -60, count: 256)
        smoothedPerturbation = [Float](repeating: 0,   count: 256)
        historyIndex = 0
        rmsHistory = [Float](repeating: -60, count: historyCapacity)
        currentMetrics = .empty
    }

    // MARK: - Processing

    private func process(_ raw: AudioMetrics) {
        // --- Scalar EMA ---
        smoothedRMS     = ema(smoothedRMS,     towards: raw.rmsLevel,  alpha: scalarAlpha)
        smoothedPeak    = ema(smoothedPeak,     towards: raw.peakLevel, alpha: scalarAlpha)
        smoothedLatency = Double(ema(Float(smoothedLatency), towards: Float(raw.latencyMs), alpha: scalarAlpha))

        // --- Spectrum EMA (per-bin) ---
        applyEMA(into: &smoothedSpectrum,     from: raw.spectrumData,         alpha: spectrumAlpha)
        applyEMA(into: &smoothedMasking,      from: raw.maskingThreshold,     alpha: spectrumAlpha)
        applyEMA(into: &smoothedPerturbation, from: raw.perturbationSpectrum, alpha: spectrumAlpha)

        // --- History ring buffer ---
        rmsHistory[historyIndex] = smoothedRMS
        historyIndex = (historyIndex + 1) % historyCapacity

        // --- Publish ---
        var out = raw
        out.rmsLevel            = smoothedRMS
        out.peakLevel           = smoothedPeak
        out.latencyMs           = smoothedLatency
        out.spectrumData        = smoothedSpectrum
        out.maskingThreshold    = smoothedMasking
        out.perturbationSpectrum = smoothedPerturbation
        currentMetrics = out
    }

    // MARK: - Helpers

    @inline(__always)
    private func ema(_ current: Float, towards target: Float, alpha: Float) -> Float {
        current + alpha * (target - current)
    }

    /// Per-bin EMA: `out[i] = out[i] + alpha * (src[i] - out[i])`
    /// Vectorised with vDSP: ~10× faster than scalar loop at 256 bins × 30 Hz.
    private func applyEMA(into out: inout [Float], from src: [Float], alpha: Float) {
        let n = vDSP_Length(min(out.count, src.count))
        // diff = src - out
        var diff = [Float](repeating: 0, count: Int(n))
        vDSP_vsub(out, 1, src, 1, &diff, 1, n)
        // out += alpha * diff
        var a = alpha
        vDSP_vsma(diff, 1, &a, out, 1, &out, 1, n)
    }
}
