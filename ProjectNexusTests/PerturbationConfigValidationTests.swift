import XCTest
@testable import ProjectNexus

/// End-to-end tests for PerturbationConfig validation logic.
/// These exercise the property-observer guards added to enforce invariants.
final class PerturbationConfigValidationTests: XCTestCase {

    // MARK: - Intensity clamping

    func test_intensity_clampsAboveOne() {
        var config = PerturbationConfig()
        config.intensity = 1.5
        XCTAssertEqual(config.intensity, 1.0, accuracy: 1e-6)
    }

    func test_intensity_clampsBelowZero() {
        var config = PerturbationConfig()
        config.intensity = -0.2
        XCTAssertEqual(config.intensity, 0.0, accuracy: 1e-6)
    }

    func test_intensity_acceptsValidRange() {
        var config = PerturbationConfig()
        config.intensity = 0.6
        XCTAssertEqual(config.intensity, 0.6, accuracy: 1e-6)
    }

    // MARK: - Frequency range ordering

    func test_frequencyRangeLow_cannotExceedHighMinus200() {
        var config = PerturbationConfig()
        config.frequencyRangeHigh = 2_000
        config.frequencyRangeLow = 1_900  // would violate low < high - 200
        // low should be pushed below high - 200, or high should be raised
        XCTAssertLessThan(config.frequencyRangeLow, config.frequencyRangeHigh)
    }

    func test_frequencyRangeHigh_cannotFallBelowLowPlus200() {
        var config = PerturbationConfig()
        config.frequencyRangeLow = 1_000
        config.frequencyRangeHigh = 1_100  // only 100 Hz gap — should be corrected
        XCTAssertGreaterThan(config.frequencyRangeHigh, config.frequencyRangeLow)
    }

    func test_frequencyRange_gapAlwaysAtLeast200Hz() {
        var config = PerturbationConfig()
        // Set a tight band and verify the gap is maintained
        config.frequencyRangeLow = 2_000
        config.frequencyRangeHigh = 2_100  // < 200 Hz gap
        let gap = config.frequencyRangeHigh - config.frequencyRangeLow
        XCTAssertGreaterThanOrEqual(gap, 200,
            "Frequency gap must be ≥ 200 Hz, got \(gap)")
    }

    func test_frequencyRangeLow_clampsToMinimum() {
        var config = PerturbationConfig()
        config.frequencyRangeLow = 10  // below 80 Hz minimum
        XCTAssertGreaterThanOrEqual(config.frequencyRangeLow, 80)
    }

    func test_frequencyRangeHigh_clampsToMaximum() {
        var config = PerturbationConfig()
        config.frequencyRangeHigh = 99_999
        XCTAssertLessThanOrEqual(config.frequencyRangeHigh, 8_000)
    }

    func test_frequencyRange_validBandPreserved() {
        var config = PerturbationConfig()
        config.frequencyRangeLow = 300
        config.frequencyRangeHigh = 4_000
        XCTAssertEqual(config.frequencyRangeLow, 300, accuracy: 1e-6)
        XCTAssertEqual(config.frequencyRangeHigh, 4_000, accuracy: 1e-6)
    }

    // MARK: - Masking aggressiveness clamping

    func test_maskingAggressiveness_clampsAboveOne() {
        var config = PerturbationConfig()
        config.maskingAggressiveness = 1.3
        XCTAssertEqual(config.maskingAggressiveness, 1.0, accuracy: 1e-6)
    }

    func test_maskingAggressiveness_clampsBelowZero() {
        var config = PerturbationConfig()
        config.maskingAggressiveness = -0.5
        XCTAssertEqual(config.maskingAggressiveness, 0.0, accuracy: 1e-6)
    }

    // MARK: - isEffective

    func test_isEffective_withDefaultConfig_isTrue() {
        let config = PerturbationConfig()
        XCTAssertTrue(config.isEffective)
    }

    func test_isEffective_withBothTiersDisabled_isFalse() {
        var config = PerturbationConfig()
        config.tier1Enabled = false
        config.tier2Enabled = false
        XCTAssertFalse(config.isEffective)
    }

    func test_isEffective_withTier1OnlyAndTechniquesEnabled_isTrue() {
        var config = PerturbationConfig()
        config.tier2Enabled = false
        config.tier1Enabled = true
        // spectralNotch is enabled by default
        XCTAssertTrue(config.isEffective)
    }

    func test_isEffective_withAllTier1TechniquesDisabled_andTier2Disabled() {
        var config = PerturbationConfig()
        config.tier2Enabled = false
        config.tier1Enabled = true
        // Disable all tier 1 techniques
        for technique in PerturbationTechnique.allCases where technique.tier == .tier1 {
            if config.isTechniqueEnabled(technique) {
                config.toggleTechnique(technique)
            }
        }
        XCTAssertFalse(config.isEffective)
    }

    // MARK: - Codable round-trip with validation

    func test_codableRoundTrip_preservesClampedValues() throws {
        var config = PerturbationConfig()
        config.intensity = 0.55
        config.frequencyRangeLow = 500
        config.frequencyRangeHigh = 6_000
        config.maskingAggressiveness = 0.6

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(PerturbationConfig.self, from: data)

        XCTAssertEqual(decoded.intensity, config.intensity, accuracy: 1e-5)
        XCTAssertEqual(decoded.frequencyRangeLow, config.frequencyRangeLow, accuracy: 1e-5)
        XCTAssertEqual(decoded.frequencyRangeHigh, config.frequencyRangeHigh, accuracy: 1e-5)
        XCTAssertEqual(decoded.maskingAggressiveness, config.maskingAggressiveness, accuracy: 1e-5)
    }
}
