import XCTest
@testable import ProjectNexus

final class UAPManagerTests: XCTestCase {

    // MARK: - Helpers

    private func fillBuffer(manager: UAPManager, count: Int = 512, gain: Float = 1.0) -> [Float] {
        var buffer = [Float](repeating: 0, count: count)
        buffer.withUnsafeMutableBufferPointer { ptr in
            manager.fillBuffer(ptr.baseAddress!, frameCount: count, gain: gain)
        }
        return buffer
    }

    // MARK: - UAPVariant enum

    func test_uapVariant_allCasesCount_isThree() {
        XCTAssertEqual(UAPVariant.allCases.count, 3)
    }

    func test_uapVariant_allCases_haveUniqueIds() {
        let ids = UAPVariant.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All UAPVariant ids must be unique")
    }

    func test_uapVariant_whisper_hasExpectedRawValue() {
        XCTAssertEqual(UAPVariant.whisperOptimized.rawValue, "Whisper")
    }

    func test_uapVariant_deepSpeech_hasExpectedRawValue() {
        XCTAssertEqual(UAPVariant.deepspeechOptimized.rawValue, "DeepSpeech")
    }

    func test_uapVariant_ensemble_hasExpectedRawValue() {
        XCTAssertEqual(UAPVariant.ensemble.rawValue, "Ensemble")
    }

    func test_uapVariant_allCases_haveNonEmptyFilenames() {
        for variant in UAPVariant.allCases {
            XCTAssertFalse(variant.filename.isEmpty,
                           "\(variant.rawValue) filename must not be empty")
        }
    }

    func test_uapVariant_filenamesAreDistinct() {
        let filenames = UAPVariant.allCases.map { $0.filename }
        let unique = Set(filenames)
        XCTAssertEqual(filenames.count, unique.count, "Each variant must have a unique filename")
    }

    // MARK: - Initial state

    func test_init_isNotLoaded() {
        let manager = UAPManager()
        XCTAssertFalse(manager.isLoaded, "UAPManager should not be loaded before loadUAPs() is called")
    }

    func test_init_defaultVariant_isEnsemble() {
        let manager = UAPManager()
        XCTAssertEqual(manager.currentVariant, .ensemble)
    }

    // MARK: - fillBuffer before load

    func test_fillBuffer_beforeLoad_producesZeroOutput() {
        let manager = UAPManager()
        let output = fillBuffer(manager: manager)
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "fillBuffer before loadUAPs() should produce zero output (no buffers loaded)")
    }

    func test_fillBuffer_beforeLoad_doesNotCrash() {
        let manager = UAPManager()
        _ = fillBuffer(manager: manager, count: 4096)
    }

    // MARK: - loadUAPs

    func test_loadUAPs_setsIsLoadedTrue() {
        let manager = UAPManager()
        manager.loadUAPs()
        XCTAssertTrue(manager.isLoaded)
    }

    func test_loadUAPs_calledTwice_doesNotCrash() {
        let manager = UAPManager()
        manager.loadUAPs()
        manager.loadUAPs()  // idempotent call
        XCTAssertTrue(manager.isLoaded)
    }

    // MARK: - fillBuffer after load (uses placeholder UAPs — no bundle resources in test target)

    func test_fillBuffer_afterLoad_producesNonZeroOutput() {
        let manager = UAPManager()
        manager.loadUAPs()
        let output = fillBuffer(manager: manager, count: 1024)
        XCTAssertTrue(output.contains { $0 != 0 },
                      "fillBuffer after loadUAPs() should produce non-zero output (placeholder UAP active)")
    }

    func test_fillBuffer_afterLoad_outputIsBounded() {
        // Placeholder UAP is normalised to epsilon = 0.01; with gain = 1.0 max amplitude ≈ 0.01
        let manager = UAPManager()
        manager.loadUAPs()
        let output = fillBuffer(manager: manager, count: 8192, gain: 1.0)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAbs, 0.05,
                                 "Placeholder UAP amplitude should be small (normalised to 0.01)")
    }

    func test_fillBuffer_gainZero_producesZeroOutput() {
        let manager = UAPManager()
        manager.loadUAPs()
        let output = fillBuffer(manager: manager, count: 1024, gain: 0.0)
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "gain = 0 should produce zero output")
    }

    func test_fillBuffer_writesExactFrameCount() {
        let manager = UAPManager()
        manager.loadUAPs()
        let count = 384
        let output = fillBuffer(manager: manager, count: count)
        XCTAssertEqual(output.count, count)
    }

    // MARK: - selectVariant

    func test_selectVariant_whisper_changesCurrentVariant() {
        let manager = UAPManager()
        manager.selectVariant(.whisperOptimized)
        XCTAssertEqual(manager.currentVariant, .whisperOptimized)
    }

    func test_selectVariant_deepSpeech_changesCurrentVariant() {
        let manager = UAPManager()
        manager.selectVariant(.deepspeechOptimized)
        XCTAssertEqual(manager.currentVariant, .deepspeechOptimized)
    }

    func test_selectVariant_ensemble_changesCurrentVariant() {
        let manager = UAPManager()
        manager.selectVariant(.ensemble)
        XCTAssertEqual(manager.currentVariant, .ensemble)
    }

    func test_selectVariant_beforeLoad_doesNotCrash() {
        let manager = UAPManager()
        manager.selectVariant(.whisperOptimized)
        XCTAssertEqual(manager.currentVariant, .whisperOptimized)
    }

    // MARK: - All variants produce output after load

    func test_allVariants_afterLoad_produceNonZeroOutput() {
        for variant in UAPVariant.allCases {
            let manager = UAPManager()
            manager.loadUAPs()
            manager.selectVariant(variant)
            let output = fillBuffer(manager: manager, count: 1024)
            XCTAssertTrue(output.contains { $0 != 0 },
                          "Variant \(variant.rawValue) should produce non-zero output")
        }
    }

    func test_allVariants_afterLoad_outputIsBounded() {
        for variant in UAPVariant.allCases {
            let manager = UAPManager()
            manager.loadUAPs()
            manager.selectVariant(variant)
            let output = fillBuffer(manager: manager, count: 4096)
            let maxAbs = output.map { abs($0) }.max() ?? 0
            XCTAssertLessThanOrEqual(maxAbs, 0.05,
                                     "Variant \(variant.rawValue) output should be bounded")
        }
    }

    // MARK: - Circular read (wrap-around)

    func test_fillBuffer_wrapAround_doesNotCrash() {
        let manager = UAPManager()
        manager.loadUAPs()
        // Placeholder UAP is 48000 samples. Request more than that to force wrap.
        let output = fillBuffer(manager: manager, count: 60000)
        XCTAssertEqual(output.count, 60000)
    }

    func test_fillBuffer_multipleCalls_advancePlayhead() {
        let manager = UAPManager()
        manager.loadUAPs()
        let out1 = fillBuffer(manager: manager, count: 1024)
        let out2 = fillBuffer(manager: manager, count: 1024)
        // Read position should advance — outputs should differ
        XCTAssertNotEqual(out1, out2,
                          "Successive fills should advance the read position")
    }

    // MARK: - Crossfade at loop boundary

    func test_fillBuffer_crossfadeRegion_doesNotProduceNaN() {
        let manager = UAPManager()
        manager.loadUAPs()
        // Fill up to the crossfade region (last 2400 samples of 48000-sample placeholder)
        var buffer = [Float](repeating: 0, count: 45601)
        buffer.withUnsafeMutableBufferPointer { ptr in
            manager.fillBuffer(ptr.baseAddress!, frameCount: 45601, gain: 1.0)
        }
        // Now fill the crossfade region
        let crossfadeOutput = fillBuffer(manager: manager, count: 2400)
        XCTAssertFalse(crossfadeOutput.contains { $0.isNaN },
                       "Crossfade region should not produce NaN")
        XCTAssertFalse(crossfadeOutput.contains { $0.isInfinite },
                       "Crossfade region should not produce Inf")
    }

    // MARK: - selectVariant after fill does not reset unrelated variants

    func test_selectVariant_switchingBetweenVariants_doesNotCrash() {
        let manager = UAPManager()
        manager.loadUAPs()
        for _ in 0..<10 {
            manager.selectVariant(.whisperOptimized)
            _ = fillBuffer(manager: manager, count: 256)
            manager.selectVariant(.ensemble)
            _ = fillBuffer(manager: manager, count: 256)
            manager.selectVariant(.deepspeechOptimized)
            _ = fillBuffer(manager: manager, count: 256)
        }
    }
}
