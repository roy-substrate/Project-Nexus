import XCTest
@testable import ProjectNexus

final class SpectralNotchGeneratorTests: XCTestCase {

    private let sampleRate: Double = 48000

    // MARK: - Helpers

    private func fillBuffer(generator: SpectralNotchGenerator, count: Int = 512) -> [Float] {
        var buffer = [Float](repeating: 0, count: count)
        buffer.withUnsafeMutableBufferPointer { ptr in
            generator.fillBuffer(ptr.baseAddress!, frameCount: count, sampleRate: sampleRate)
        }
        return buffer
    }

    // MARK: - Initialisation

    func test_init_isEnabled() {
        let gen = SpectralNotchGenerator()
        XCTAssertTrue(gen.isEnabled)
    }

    func test_init_customIntensity_isEnabled() {
        let gen = SpectralNotchGenerator(intensity: 0.3)
        XCTAssertTrue(gen.isEnabled)
    }

    // MARK: - Output level

    func test_fillBuffer_defaultIntensity_producesNonZeroOutput() {
        let gen = SpectralNotchGenerator()
        let output = fillBuffer(generator: gen)
        XCTAssertTrue(output.contains { $0 != 0 },
                      "Expected non-zero output at default intensity")
    }

    func test_fillBuffer_zeroIntensity_producesZeroOutput() {
        let gen = SpectralNotchGenerator()
        gen.setIntensity(0)
        let output = fillBuffer(generator: gen)
        // scale = 0 * 0.15 = 0 → all samples should be zero
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "Expected all-zero output when intensity = 0")
    }

    func test_fillBuffer_outputScalesWithIntensity() {
        // Same noise table, only scale changes — RMS should scale linearly
        let genLow = SpectralNotchGenerator(intensity: 0.1)
        let genHigh = SpectralNotchGenerator(intensity: 0.9)

        let outLow = fillBuffer(generator: genLow, count: 4096)
        let outHigh = fillBuffer(generator: genHigh, count: 4096)

        let rmsLow = sqrt(outLow.map { $0 * $0 }.reduce(0, +) / Float(outLow.count))
        let rmsHigh = sqrt(outHigh.map { $0 * $0 }.reduce(0, +) / Float(outHigh.count))

        XCTAssertGreaterThan(rmsHigh, rmsLow,
                             "Higher intensity should produce higher RMS")
    }

    func test_fillBuffer_outputAmplitudeIsBounded() {
        // Scale = 1.0 * 0.15 = 0.15; noise table is normalised to peak = 1 before crossfade
        let gen = SpectralNotchGenerator(intensity: 1.0)
        let output = fillBuffer(generator: gen, count: 8192)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAbs, 0.2, "Output amplitude should be bounded by scale factor (max ≈ 0.15)")
    }

    // MARK: - setIntensity clamping

    func test_setIntensity_negativeClampsToZero() {
        let gen = SpectralNotchGenerator()
        gen.setIntensity(-1.0)
        let output = fillBuffer(generator: gen)
        XCTAssertTrue(output.allSatisfy { $0 == 0 })
    }

    func test_setIntensity_aboveOneClampsToOne() {
        let gen = SpectralNotchGenerator()
        gen.setIntensity(99.0)
        let output = fillBuffer(generator: gen, count: 4096)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        // Clamped to 1.0 → scale = 0.15 → max ≈ 0.15
        XCTAssertLessThanOrEqual(maxAbs, 0.2)
    }

    // MARK: - Wrap-around (frame count > noise table size)

    func test_fillBuffer_frameCountLargerThanNoiseTable_doesNotCrash() {
        // noiseTableSize = 48000 samples; request 50000 to force wrap
        let gen = SpectralNotchGenerator()
        let output = fillBuffer(generator: gen, count: 50000)
        XCTAssertEqual(output.count, 50000)
    }

    func test_fillBuffer_frameCountLargerThanNoiseTable_producesNonZeroOutput() {
        let gen = SpectralNotchGenerator(intensity: 1.0)
        let output = fillBuffer(generator: gen, count: 50000)
        XCTAssertTrue(output.contains { $0 != 0 })
    }

    // MARK: - Playhead advances

    func test_fillBuffer_twoCalls_produceDifferentOutput() {
        let gen = SpectralNotchGenerator()
        let out1 = fillBuffer(generator: gen, count: 256)
        let out2 = fillBuffer(generator: gen, count: 256)
        XCTAssertNotEqual(out1, out2,
                          "Successive fills should advance the read position")
    }

    func test_fillBuffer_readPositionWraps_doesNotCrash() {
        let gen = SpectralNotchGenerator(intensity: 0.5)
        // Fill past end of noise table multiple times
        for _ in 0..<5 {
            _ = fillBuffer(generator: gen, count: 16000)
        }
    }

    // MARK: - isEnabled

    func test_isEnabled_canBeSetFalse() {
        let gen = SpectralNotchGenerator()
        gen.isEnabled = false
        XCTAssertFalse(gen.isEnabled)
    }

    // MARK: - updateMaskingThreshold

    func test_updateMaskingThreshold_emptyArray_doesNotCrash() {
        let gen = SpectralNotchGenerator()
        gen.updateMaskingThreshold([])
    }

    func test_updateMaskingThreshold_validArray_doesNotCrash() {
        let gen = SpectralNotchGenerator()
        gen.updateMaskingThreshold([Float](repeating: -30, count: 512))
    }

    func test_updateMaskingThreshold_calledConcurrently_doesNotCrash() {
        let gen = SpectralNotchGenerator()
        let exp = expectation(description: "concurrent updates")
        exp.expectedFulfillmentCount = 2

        DispatchQueue.global().async {
            for _ in 0..<100 { gen.updateMaskingThreshold([Float](repeating: -20, count: 256)) }
            exp.fulfill()
        }
        DispatchQueue.global().async {
            for _ in 0..<100 { _ = self.fillBuffer(generator: gen, count: 512) }
            exp.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: - Exact frame count written

    func test_fillBuffer_writesExactFrameCount() {
        let gen = SpectralNotchGenerator()
        let count = 1024
        let output = fillBuffer(generator: gen, count: count)
        XCTAssertEqual(output.count, count)
    }
}
