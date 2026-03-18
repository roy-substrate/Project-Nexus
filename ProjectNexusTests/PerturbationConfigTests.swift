import XCTest
@testable import ProjectNexus

final class PerturbationConfigTests: XCTestCase {

    // MARK: - Default values

    func test_defaultConfig_hasExpectedIntensity() {
        let config = PerturbationConfig()
        XCTAssertEqual(config.intensity, 0.8, accuracy: 1e-6)
    }

    func test_defaultConfig_frequencyRangeLow() {
        let config = PerturbationConfig()
        XCTAssertEqual(config.frequencyRangeLow, 17_000.0, accuracy: 1e-6)
    }

    func test_defaultConfig_frequencyRangeHigh() {
        let config = PerturbationConfig()
        XCTAssertEqual(config.frequencyRangeHigh, 20_000.0, accuracy: 1e-6)
    }

    func test_defaultConfig_bothTiersEnabled() {
        let config = PerturbationConfig()
        XCTAssertTrue(config.tier1Enabled)
        XCTAssertTrue(config.tier2Enabled)
    }

    func test_defaultConfig_hasExpectedEnabledTechniques() {
        let config = PerturbationConfig()
        XCTAssertTrue(config.isTechniqueEnabled(.spectralNotch))
        XCTAssertTrue(config.isTechniqueEnabled(.babbleNoise))
        XCTAssertTrue(config.isTechniqueEnabled(.frequencySweep))
        XCTAssertTrue(config.isTechniqueEnabled(.uapEnsemble))
    }

    func test_defaultConfig_tier2TechniquesNotEnabled() {
        let config = PerturbationConfig()
        XCTAssertFalse(config.isTechniqueEnabled(.uapWhisper))
        XCTAssertFalse(config.isTechniqueEnabled(.uapDeepSpeech))
    }

    // MARK: - toggleTechnique

    func test_toggleTechnique_disablesEnabledTechnique() {
        var config = PerturbationConfig()
        XCTAssertTrue(config.isTechniqueEnabled(.spectralNotch))
        config.toggleTechnique(.spectralNotch)
        XCTAssertFalse(config.isTechniqueEnabled(.spectralNotch))
    }

    func test_toggleTechnique_enablesDisabledTechnique() {
        var config = PerturbationConfig()
        XCTAssertFalse(config.isTechniqueEnabled(.uapWhisper))
        config.toggleTechnique(.uapWhisper)
        XCTAssertTrue(config.isTechniqueEnabled(.uapWhisper))
    }

    func test_toggleTechnique_doubleToggle_restoresOriginalState() {
        var config = PerturbationConfig()
        let initialState = config.isTechniqueEnabled(.babbleNoise)
        config.toggleTechnique(.babbleNoise)
        config.toggleTechnique(.babbleNoise)
        XCTAssertEqual(config.isTechniqueEnabled(.babbleNoise), initialState)
    }

    func test_toggleTechnique_doesNotAffectOtherTechniques() {
        var config = PerturbationConfig()
        let beforeSweep = config.isTechniqueEnabled(.frequencySweep)
        config.toggleTechnique(.spectralNotch)
        XCTAssertEqual(config.isTechniqueEnabled(.frequencySweep), beforeSweep)
    }

    // MARK: - Codable

    func test_config_canBeEncodedAndDecoded() throws {
        var config = PerturbationConfig()
        config.intensity = 0.5
        config.frequencyRangeLow = 17_200.0
        config.frequencyRangeHigh = 21_000.0
        config.tier1Enabled = false
        config.toggleTechnique(.uapWhisper)

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(PerturbationConfig.self, from: data)

        XCTAssertEqual(decoded.intensity, config.intensity, accuracy: 1e-6)
        XCTAssertEqual(decoded.frequencyRangeLow, config.frequencyRangeLow, accuracy: 1e-6)
        XCTAssertEqual(decoded.frequencyRangeHigh, config.frequencyRangeHigh, accuracy: 1e-6)
        XCTAssertEqual(decoded.tier1Enabled, config.tier1Enabled)
        XCTAssertEqual(decoded.isTechniqueEnabled(.uapWhisper), config.isTechniqueEnabled(.uapWhisper))
    }
}

// MARK: - CodecTarget Tests

final class CodecTargetTests: XCTestCase {

    func test_opus32k_bitrateHz() {
        XCTAssertEqual(CodecTarget.opus32k.bitrateHz, 32_000)
    }

    func test_opus64k_bitrateHz() {
        XCTAssertEqual(CodecTarget.opus64k.bitrateHz, 64_000)
    }

    func test_opus128k_bitrateHz() {
        XCTAssertEqual(CodecTarget.opus128k.bitrateHz, 128_000)
    }

    func test_aac64k_bitrateHz() {
        XCTAssertEqual(CodecTarget.aac64k.bitrateHz, 64_000)
    }

    func test_none_bitrateHz_isZero() {
        XCTAssertEqual(CodecTarget.none.bitrateHz, 0)
    }

    func test_allCases_haveUniqueRawValues() {
        let rawValues = CodecTarget.allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count)
    }

    func test_allCases_idMatchesRawValue() {
        for target in CodecTarget.allCases {
            XCTAssertEqual(target.id, target.rawValue)
        }
    }

    func test_codecTarget_isCodable() throws {
        let target = CodecTarget.aac64k
        let data = try JSONEncoder().encode(target)
        let decoded = try JSONDecoder().decode(CodecTarget.self, from: data)
        XCTAssertEqual(decoded, target)
    }
}
