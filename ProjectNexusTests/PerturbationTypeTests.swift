import XCTest
@testable import ProjectNexus

final class PerturbationTierTests: XCTestCase {

    func test_tier1_rawValue() {
        XCTAssertEqual(PerturbationTier.tier1.rawValue, "Acoustic")
    }

    func test_tier2_rawValue() {
        XCTAssertEqual(PerturbationTier.tier2.rawValue, "Adversarial")
    }

    func test_tier1_idMatchesRawValue() {
        XCTAssertEqual(PerturbationTier.tier1.id, PerturbationTier.tier1.rawValue)
    }

    func test_tier2_idMatchesRawValue() {
        XCTAssertEqual(PerturbationTier.tier2.id, PerturbationTier.tier2.rawValue)
    }

    func test_tier1_descriptionIsNonEmpty() {
        XCTAssertFalse(PerturbationTier.tier1.description.isEmpty)
    }

    func test_tier2_descriptionIsNonEmpty() {
        XCTAssertFalse(PerturbationTier.tier2.description.isEmpty)
    }

    func test_tiers_haveDifferentDescriptions() {
        XCTAssertNotEqual(PerturbationTier.tier1.description, PerturbationTier.tier2.description)
    }

    func test_allCases_containsBothTiers() {
        XCTAssertEqual(PerturbationTier.allCases.count, 2)
        XCTAssertTrue(PerturbationTier.allCases.contains(.tier1))
        XCTAssertTrue(PerturbationTier.allCases.contains(.tier2))
    }

    func test_tier_isCodable() throws {
        let tier = PerturbationTier.tier2
        let data = try JSONEncoder().encode(tier)
        let decoded = try JSONDecoder().decode(PerturbationTier.self, from: data)
        XCTAssertEqual(decoded, tier)
    }
}

final class PerturbationTechniqueTests: XCTestCase {

    // MARK: - Tier classification

    func test_spectralNotch_isTier1() {
        XCTAssertEqual(PerturbationTechnique.spectralNotch.tier, .tier1)
    }

    func test_babbleNoise_isTier1() {
        XCTAssertEqual(PerturbationTechnique.babbleNoise.tier, .tier1)
    }

    func test_frequencySweep_isTier1() {
        XCTAssertEqual(PerturbationTechnique.frequencySweep.tier, .tier1)
    }

    func test_uapWhisper_isTier2() {
        XCTAssertEqual(PerturbationTechnique.uapWhisper.tier, .tier2)
    }

    func test_uapDeepSpeech_isTier2() {
        XCTAssertEqual(PerturbationTechnique.uapDeepSpeech.tier, .tier2)
    }

    func test_uapEnsemble_isTier2() {
        XCTAssertEqual(PerturbationTechnique.uapEnsemble.tier, .tier2)
    }

    func test_tier1_techniquesHaveThreeMembers() {
        let tier1 = PerturbationTechnique.allCases.filter { $0.tier == .tier1 }
        XCTAssertEqual(tier1.count, 3)
    }

    func test_tier2_techniquesHaveThreeMembers() {
        let tier2 = PerturbationTechnique.allCases.filter { $0.tier == .tier2 }
        XCTAssertEqual(tier2.count, 3)
    }

    // MARK: - Icon names

    func test_allTechniques_haveNonEmptyIconName() {
        for technique in PerturbationTechnique.allCases {
            XCTAssertFalse(technique.iconName.isEmpty,
                "\(technique.rawValue) should have a non-empty icon name")
        }
    }

    func test_allTechniques_haveUniqueIconNames() {
        let icons = PerturbationTechnique.allCases.map { $0.iconName }
        XCTAssertEqual(icons.count, Set(icons).count,
            "Each technique should have a unique SF Symbol icon name")
    }

    // MARK: - Identifiable

    func test_allCases_idMatchesRawValue() {
        for technique in PerturbationTechnique.allCases {
            XCTAssertEqual(technique.id, technique.rawValue)
        }
    }

    // MARK: - Codable

    func test_technique_isCodable() throws {
        let technique = PerturbationTechnique.uapEnsemble
        let data = try JSONEncoder().encode(technique)
        let decoded = try JSONDecoder().decode(PerturbationTechnique.self, from: data)
        XCTAssertEqual(decoded, technique)
    }

    // MARK: - All cases

    func test_allCases_hasSixTechniques() {
        XCTAssertEqual(PerturbationTechnique.allCases.count, 6)
    }

    func test_allCases_rawValuesAreUnique() {
        let rawValues = PerturbationTechnique.allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count)
    }
}
