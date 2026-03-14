import Foundation

struct AudioMetrics: Sendable {
    var latencyMs: Double = 0
    var rmsLevel: Float = -60.0
    var peakLevel: Float = -60.0
    var bufferUnderruns: Int = 0
    var spectrumData: [Float] = Array(repeating: 0, count: 256)
    var maskingThreshold: [Float] = Array(repeating: -60, count: 256)
    var perturbationSpectrum: [Float] = Array(repeating: 0, count: 256)
    var isEngineRunning: Bool = false
    var cpuUsage: Double = 0

    static let empty = AudioMetrics()
}
