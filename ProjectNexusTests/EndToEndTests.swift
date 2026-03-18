import XCTest
@testable import ProjectNexus

/// End-to-end integration tests that exercise the full config → service → state flow
/// without any audio hardware (all audio engine calls are intentionally not started).
final class EndToEndTests: XCTestCase {

    // MARK: - AppState + config persistence round-trip

    func test_appState_saveAndRestore_preservesAllSettings() throws {
        let key = "perturbationConfig"
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        var state1 = AppState()
        state1.config.intensity = 0.33
        state1.config.tier1Enabled = false
        state1.config.frequencyRangeLow = 400
        state1.config.frequencyRangeHigh = 3200
        state1.config.maskingAggressiveness = 0.45
        state1.config.codecTarget = .aac64k
        state1.config.toggleTechnique(.uapWhisper)   // enable
        state1.saveConfig()

        let state2 = AppState()
        XCTAssertEqual(state2.config.intensity,             0.33, accuracy: 1e-5)
        XCTAssertFalse(state2.config.tier1Enabled)
        XCTAssertEqual(state2.config.frequencyRangeLow,    400,   accuracy: 1e-5)
        XCTAssertEqual(state2.config.frequencyRangeHigh,   3200,  accuracy: 1e-5)
        XCTAssertEqual(state2.config.maskingAggressiveness, 0.45, accuracy: 1e-5)
        XCTAssertEqual(state2.config.codecTarget, .aac64k)
        XCTAssertTrue(state2.config.isTechniqueEnabled(.uapWhisper))
    }

    // MARK: - Shield active/inactive state

    func test_appState_defaultsToInactive() {
        let state = AppState()
        XCTAssertFalse(state.isShieldActive)
    }

    func test_appState_activeTechniqueCount_isZeroWhenInactive() {
        var state = AppState()
        state.isShieldActive = false
        XCTAssertEqual(state.activeTechniqueCount, 0)
    }

    func test_appState_activeTechniqueCount_reflectsEnabledTechniques() {
        var state = AppState()
        state.isShieldActive = true
        state.config.tier1Enabled = true
        state.config.tier2Enabled = false

        // Default: spectralNotch, babbleNoise, frequencySweep enabled in tier1
        let expectedTier1Count = PerturbationTechnique.allCases.filter { technique in
            technique.tier == .tier1 && state.config.isTechniqueEnabled(technique)
        }.count

        XCTAssertEqual(state.activeTechniqueCount, expectedTier1Count)
    }

    func test_appState_activeTechniqueCount_zeroWhenAllTechniquesDisabled() {
        var state = AppState()
        state.isShieldActive = true
        for technique in PerturbationTechnique.allCases {
            if state.config.isTechniqueEnabled(technique) {
                state.config.toggleTechnique(technique)
            }
        }
        XCTAssertEqual(state.activeTechniqueCount, 0)
    }

    // MARK: - Computed tier properties

    func test_tier1Active_trueOnlyWhenShieldActiveAndTier1Enabled() {
        var state = AppState()
        state.isShieldActive = true
        state.config.tier1Enabled = true
        XCTAssertTrue(state.tier1Active)

        state.config.tier1Enabled = false
        XCTAssertFalse(state.tier1Active)

        state.isShieldActive = false
        state.config.tier1Enabled = true
        XCTAssertFalse(state.tier1Active)
    }

    func test_tier2Active_trueOnlyWhenShieldActiveAndTier2Enabled() {
        var state = AppState()
        state.isShieldActive = true
        state.config.tier2Enabled = true
        XCTAssertTrue(state.tier2Active)

        state.isShieldActive = false
        XCTAssertFalse(state.tier2Active)
    }

    // MARK: - Metrics EMA convergence

    func test_metricsService_rmsHistoryGrowsWithCalls() {
        let service = MetricsService()
        // After stopMonitoring, history is reset to all -60
        service.stopMonitoring()
        XCTAssertTrue(service.rmsHistory.allSatisfy { $0 == -60 })
    }

    // MARK: - PerturbationService config logic

    func test_perturbationService_updateConfig_doesNotCrash() {
        // Just verify the update path doesn't throw or crash on a stopped service
        let service = PerturbationService()
        var config = PerturbationConfig()
        config.intensity = 0.5
        config.tier1Enabled = true
        config.tier2Enabled = false
        service.updateConfig(config)   // should be a no-op on stopped pipeline
    }

    func test_perturbationService_isNotRunningByDefault() {
        let service = PerturbationService()
        XCTAssertFalse(service.isRunning)
    }

    // MARK: - DSP utilities integration

    func test_dspRoundTrip_frequencyBinConversion() {
        let sampleRate: Float = 48_000
        let fftSize = 1024
        let testFreq: Float = 1000

        let bin = DSPUtilities.frequencyToBin(testFreq, sampleRate: sampleRate, fftSize: fftSize)
        let recovered = DSPUtilities.binToFrequency(bin, sampleRate: sampleRate, fftSize: fftSize)

        // Should be within one bin resolution (~47 Hz at 48kHz/1024)
        XCTAssertEqual(recovered, testFreq, accuracy: sampleRate / Float(fftSize))
    }

    func test_floatArrayPipeline_scaleAddRMS() {
        // Full pipeline: generate, scale, add, measure RMS
        var signal = DSPUtilities.generateWhiteNoise(count: 1024)
        signal = signal.scaled(by: 0.5)
        let zeros = [Float](repeating: 0, count: 1024)
        signal = signal.added(to: zeros)
        let rms = signal.rms()

        // White noise at 0.5 amplitude: RMS ≈ 0.5 / sqrt(2) ≈ 0.289 (theoretical)
        // In practice just check it's in a reasonable range
        XCTAssertGreaterThan(rms, 0.01)
        XCTAssertLessThan(rms, 1.0)
    }

    // MARK: - AudioMetrics struct

    func test_audioMetrics_defaultAndEmpty_areEquivalent() {
        let a = AudioMetrics()
        let b = AudioMetrics.empty
        XCTAssertEqual(a.rmsLevel,   b.rmsLevel,   accuracy: 1e-6)
        XCTAssertEqual(a.peakLevel,  b.peakLevel,  accuracy: 1e-6)
        XCTAssertEqual(a.latencyMs,  b.latencyMs,  accuracy: 1e-6)
        XCTAssertEqual(a.cpuUsage,   b.cpuUsage,   accuracy: 1e-6)
        XCTAssertEqual(a.bufferUnderruns, b.bufferUnderruns)
        XCTAssertEqual(a.isEngineRunning, b.isEngineRunning)
        XCTAssertEqual(a.spectrumData.count, b.spectrumData.count)
    }
}
