import XCTest
@testable import ProjectNexus

final class MetricsServiceTests: XCTestCase {

    // MARK: - Initial state

    func test_initialMetrics_areEmpty() {
        let service = MetricsService()
        XCTAssertEqual(service.currentMetrics.rmsLevel, -60, accuracy: 1e-5)
        XCTAssertFalse(service.currentMetrics.isEngineRunning)
    }

    func test_rmsHistory_initialLength() {
        let service = MetricsService()
        XCTAssertEqual(service.rmsHistory.count, 60)
    }

    func test_rmsHistory_initiallyAllSilence() {
        let service = MetricsService()
        XCTAssertTrue(service.rmsHistory.allSatisfy { $0 == -60 })
    }

    // MARK: - stopMonitoring resets state

    func test_stopMonitoring_resetsMetrics() {
        let service = MetricsService()
        service.stopMonitoring()
        XCTAssertEqual(service.currentMetrics.rmsLevel, -60, accuracy: 1e-5)
    }

    func test_stopMonitoring_resetsHistory() {
        let service = MetricsService()
        service.stopMonitoring()
        XCTAssertTrue(service.rmsHistory.allSatisfy { $0 == -60 })
    }
}

// MARK: - AppState persistence tests

final class AppStatePersistenceTests: XCTestCase {

    private let testKey = "perturbationConfig"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    func test_saveAndLoad_roundTrip() {
        var state = AppState()
        state.config.intensity = 0.42
        state.config.tier1Enabled = false
        state.saveConfig()

        // Create a fresh AppState — it should load the saved config
        let state2 = AppState()
        XCTAssertEqual(state2.config.intensity, 0.42, accuracy: 1e-5)
        XCTAssertFalse(state2.config.tier1Enabled)
    }

    func test_loadConfig_withNoSavedData_returnsDefault() {
        UserDefaults.standard.removeObject(forKey: testKey)
        let state = AppState()
        XCTAssertEqual(state.config.intensity, 0.8, accuracy: 1e-5)
    }

    func test_errorMessage_initiallyNil() {
        let state = AppState()
        XCTAssertNil(state.errorMessage)
    }
}
