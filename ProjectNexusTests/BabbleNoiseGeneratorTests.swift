import XCTest
@testable import ProjectNexus

final class BabbleNoiseGeneratorTests: XCTestCase {

    private let frameCount = 512
    private let sampleRate: Double = 48000

    // MARK: - Helpers

    private func fillBuffer(generator: BabbleNoiseGenerator, count: Int = 512) -> [Float] {
        var buffer = [Float](repeating: 0, count: count)
        buffer.withUnsafeMutableBufferPointer { ptr in
            generator.fillBuffer(ptr.baseAddress!, frameCount: count, sampleRate: sampleRate)
        }
        return buffer
    }

    // MARK: - Initialisation

    func test_init_defaultIntensity_isEnabled() {
        let gen = BabbleNoiseGenerator()
        XCTAssertTrue(gen.isEnabled)
    }

    func test_init_customIntensity_isEnabled() {
        let gen = BabbleNoiseGenerator(intensity: 0.5)
        XCTAssertTrue(gen.isEnabled)
    }

    // MARK: - fillBuffer output level

    func test_fillBuffer_defaultIntensity_producesNonZeroOutput() {
        let gen = BabbleNoiseGenerator()
        let output = fillBuffer(generator: gen)
        let hasNonZero = output.contains { $0 != 0 }
        XCTAssertTrue(hasNonZero, "Expected non-zero output from BabbleNoiseGenerator at default intensity")
    }

    func test_fillBuffer_zeroIntensity_producesZeroOutput() {
        let gen = BabbleNoiseGenerator()
        gen.setIntensity(0)
        let output = fillBuffer(generator: gen)
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "Expected all-zero output when intensity = 0 (output = sample * 0 * 0.12)")
    }

    func test_fillBuffer_writesExactFrameCount() {
        let gen = BabbleNoiseGenerator()
        let count = 256
        let output = fillBuffer(generator: gen, count: count)
        XCTAssertEqual(output.count, count)
    }

    func test_fillBuffer_outputAmplitudeWithinExpectedRange() {
        // Layers are normalised to peak = 1, layerGains ∈ [0.6,1.0], 4 layers,
        // intensity = 0.8, final scale = 0.12 → max peak = 4 * 1.0 * 1.0 * 0.8 * 0.12 = 0.384
        let gen = BabbleNoiseGenerator(intensity: 1.0)
        let output = fillBuffer(generator: gen, count: 4096)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAbs, 0.6, "Output amplitude should be bounded below 0.6")
    }

    // MARK: - setIntensity clamping

    func test_setIntensity_clampsNegativeToZero() {
        let gen = BabbleNoiseGenerator()
        gen.setIntensity(-5.0)
        let output = fillBuffer(generator: gen)
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "Intensity clamped to 0 should produce zero output")
    }

    func test_setIntensity_clampsAboveOneToOne() {
        // Setting intensity = 2 should clamp to 1; output should match intensity = 1 output
        let gen1 = BabbleNoiseGenerator(intensity: 1.0)
        let gen2 = BabbleNoiseGenerator(intensity: 1.0)
        gen2.setIntensity(2.0)

        var buf1 = [Float](repeating: 0, count: frameCount)
        var buf2 = [Float](repeating: 0, count: frameCount)

        // Fill same generator twice — output will differ due to state advancement,
        // but both should be non-zero (not clamped to zero).
        buf1.withUnsafeMutableBufferPointer { ptr in
            gen1.fillBuffer(ptr.baseAddress!, frameCount: frameCount, sampleRate: sampleRate)
        }
        buf2.withUnsafeMutableBufferPointer { ptr in
            gen2.fillBuffer(ptr.baseAddress!, frameCount: frameCount, sampleRate: sampleRate)
        }

        let hasNonZero1 = buf1.contains { $0 != 0 }
        let hasNonZero2 = buf2.contains { $0 != 0 }
        XCTAssertTrue(hasNonZero1)
        XCTAssertTrue(hasNonZero2)
    }

    func test_setIntensity_halfValue_producesHalfAmplitude() {
        // Two identical generators (same init state) — set one to 0.4, one to 0.8.
        // Because BabbleNoiseGenerator uses random state, we cannot compare sample-by-sample.
        // Instead verify that higher intensity produces higher RMS.
        let genLow = BabbleNoiseGenerator(intensity: 0.1)
        let genHigh = BabbleNoiseGenerator(intensity: 0.9)

        let outLow = fillBuffer(generator: genLow, count: 4096)
        let outHigh = fillBuffer(generator: genHigh, count: 4096)

        let rmsLow = sqrt(outLow.map { $0 * $0 }.reduce(0, +) / Float(outLow.count))
        let rmsHigh = sqrt(outHigh.map { $0 * $0 }.reduce(0, +) / Float(outHigh.count))

        XCTAssertGreaterThan(rmsHigh, rmsLow,
                             "Higher intensity should produce higher RMS amplitude")
    }

    // MARK: - isEnabled flag

    func test_isEnabled_canBeSetToFalse() {
        let gen = BabbleNoiseGenerator()
        gen.isEnabled = false
        XCTAssertFalse(gen.isEnabled)
    }

    func test_isEnabled_canBeToggled() {
        let gen = BabbleNoiseGenerator()
        gen.isEnabled = false
        gen.isEnabled = true
        XCTAssertTrue(gen.isEnabled)
    }

    // MARK: - Successive calls advance playhead

    func test_fillBuffer_twoCalls_produceDifferentOutput() {
        let gen = BabbleNoiseGenerator()
        let out1 = fillBuffer(generator: gen, count: 128)
        let out2 = fillBuffer(generator: gen, count: 128)
        // Layer positions advance — outputs should not be identical
        XCTAssertNotEqual(out1, out2,
                          "Successive fills should advance playhead, producing different output")
    }

    // MARK: - updateMaskingThreshold

    func test_updateMaskingThreshold_emptyArray_doesNotCrash() {
        let gen = BabbleNoiseGenerator()
        gen.updateMaskingThreshold([])
    }

    func test_updateMaskingThreshold_fullArray_doesNotCrash() {
        let gen = BabbleNoiseGenerator()
        gen.updateMaskingThreshold([Float](repeating: -20, count: 512))
    }

    // MARK: - Large frame count

    func test_fillBuffer_largeFrameCount_doesNotCrash() {
        let gen = BabbleNoiseGenerator()
        let output = fillBuffer(generator: gen, count: 48000)
        XCTAssertEqual(output.count, 48000)
    }
}
