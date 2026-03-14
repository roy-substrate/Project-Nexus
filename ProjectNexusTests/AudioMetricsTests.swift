import XCTest
@testable import ProjectNexus

final class AudioMetricsTests: XCTestCase {

    // MARK: - Default values

    func test_defaultMetrics_latencyIsZero() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.latencyMs, 0)
    }

    func test_defaultMetrics_rmsLevelIsSilence() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.rmsLevel, -60.0, accuracy: 1e-6)
    }

    func test_defaultMetrics_peakLevelIsSilence() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.peakLevel, -60.0, accuracy: 1e-6)
    }

    func test_defaultMetrics_bufferUnderrunsIsZero() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.bufferUnderruns, 0)
    }

    func test_defaultMetrics_spectrumDataHas256Bins() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.spectrumData.count, 256)
    }

    func test_defaultMetrics_spectrumDataIsAllZero() {
        let metrics = AudioMetrics()
        XCTAssertTrue(metrics.spectrumData.allSatisfy { $0 == 0 })
    }

    func test_defaultMetrics_maskingThresholdHas256Bins() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.maskingThreshold.count, 256)
    }

    func test_defaultMetrics_maskingThresholdIsAllSilence() {
        let metrics = AudioMetrics()
        XCTAssertTrue(metrics.maskingThreshold.allSatisfy { $0 == -60 })
    }

    func test_defaultMetrics_perturbationSpectrumHas256Bins() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.perturbationSpectrum.count, 256)
    }

    func test_defaultMetrics_engineNotRunning() {
        let metrics = AudioMetrics()
        XCTAssertFalse(metrics.isEngineRunning)
    }

    func test_defaultMetrics_cpuUsageIsZero() {
        let metrics = AudioMetrics()
        XCTAssertEqual(metrics.cpuUsage, 0)
    }

    // MARK: - Static empty

    func test_empty_matchesDefaultInit() {
        let empty = AudioMetrics.empty
        let defaultMetrics = AudioMetrics()

        XCTAssertEqual(empty.latencyMs, defaultMetrics.latencyMs)
        XCTAssertEqual(empty.rmsLevel, defaultMetrics.rmsLevel, accuracy: 1e-6)
        XCTAssertEqual(empty.peakLevel, defaultMetrics.peakLevel, accuracy: 1e-6)
        XCTAssertEqual(empty.bufferUnderruns, defaultMetrics.bufferUnderruns)
        XCTAssertEqual(empty.spectrumData.count, defaultMetrics.spectrumData.count)
        XCTAssertEqual(empty.isEngineRunning, defaultMetrics.isEngineRunning)
        XCTAssertEqual(empty.cpuUsage, defaultMetrics.cpuUsage)
    }

    // MARK: - Mutability

    func test_metrics_canBeModified() {
        var metrics = AudioMetrics()
        metrics.latencyMs = 5.3
        metrics.rmsLevel = -20.0
        metrics.isEngineRunning = true
        metrics.bufferUnderruns = 3

        XCTAssertEqual(metrics.latencyMs, 5.3, accuracy: 1e-6)
        XCTAssertEqual(metrics.rmsLevel, -20.0, accuracy: 1e-6)
        XCTAssertTrue(metrics.isEngineRunning)
        XCTAssertEqual(metrics.bufferUnderruns, 3)
    }

    func test_metrics_sendableConformance() {
        // Sendable conformance means we can pass across concurrency boundaries.
        // This test simply ensures the type compiles as Sendable.
        let metrics: any Sendable = AudioMetrics.empty
        XCTAssertNotNil(metrics)
    }
}
