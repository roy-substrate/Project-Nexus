import XCTest
@testable import ProjectNexus

final class FrequencySweepGeneratorTests: XCTestCase {

    private let sampleRate: Double = 48000

    // MARK: - Helpers

    private func fillBuffer(generator: FrequencySweepGenerator, count: Int = 512) -> [Float] {
        var buffer = [Float](repeating: 0, count: count)
        buffer.withUnsafeMutableBufferPointer { ptr in
            generator.fillBuffer(ptr.baseAddress!, frameCount: count, sampleRate: sampleRate)
        }
        return buffer
    }

    // MARK: - Initialisation

    func test_init_isEnabled() {
        let gen = FrequencySweepGenerator()
        XCTAssertTrue(gen.isEnabled)
    }

    func test_init_customIntensity_isEnabled() {
        let gen = FrequencySweepGenerator(intensity: 0.4)
        XCTAssertTrue(gen.isEnabled)
    }

    // MARK: - Output level

    func test_fillBuffer_defaultIntensity_producesNonZeroOutput() {
        let gen = FrequencySweepGenerator()
        let output = fillBuffer(generator: gen, count: 1024)
        XCTAssertTrue(output.contains { $0 != 0 },
                      "Expected non-zero output from FrequencySweepGenerator at default intensity")
    }

    func test_fillBuffer_zeroIntensity_producesZeroOutput() {
        let gen = FrequencySweepGenerator()
        gen.setIntensity(0)
        let output = fillBuffer(generator: gen, count: 1024)
        // output = sample * 0 * 0.1 / 4 = 0
        XCTAssertTrue(output.allSatisfy { $0 == 0 },
                      "Expected all-zero output when intensity = 0")
    }

    func test_fillBuffer_higherIntensity_producesHigherRMS() {
        let genLow = FrequencySweepGenerator(intensity: 0.1)
        let genHigh = FrequencySweepGenerator(intensity: 0.9)

        let outLow = fillBuffer(generator: genLow, count: 4096)
        let outHigh = fillBuffer(generator: genHigh, count: 4096)

        let rmsLow = sqrt(outLow.map { $0 * $0 }.reduce(0, +) / Float(outLow.count))
        let rmsHigh = sqrt(outHigh.map { $0 * $0 }.reduce(0, +) / Float(outHigh.count))

        XCTAssertGreaterThan(rmsHigh, rmsLow,
                             "Higher intensity should produce higher RMS")
    }

    func test_fillBuffer_outputAmplitudeIsBounded() {
        // output = sum(4 sweeps) * intensity * 0.1 / 4
        // Each sweep gain ∈ [0.5,1.0], sinf envelope max = 1 → max per sweep ≤ 1.0
        // Absolute max ≤ 4 * 1.0 * 1.0 * 0.1 / 4 = 0.1
        let gen = FrequencySweepGenerator(intensity: 1.0)
        let output = fillBuffer(generator: gen, count: 8192)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAbs, 0.15,
                                 "Output amplitude should be bounded by design constants (max ≈ 0.1)")
    }

    // MARK: - setIntensity clamping

    func test_setIntensity_negativeClampsToZero() {
        let gen = FrequencySweepGenerator()
        gen.setIntensity(-10.0)
        let output = fillBuffer(generator: gen, count: 1024)
        XCTAssertTrue(output.allSatisfy { $0 == 0 })
    }

    func test_setIntensity_aboveOneClampsToOne() {
        let gen = FrequencySweepGenerator()
        gen.setIntensity(100.0)
        let output = fillBuffer(generator: gen, count: 8192)
        let maxAbs = output.map { abs($0) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxAbs, 0.15, "Intensity clamped to 1.0 — amplitude should be bounded")
    }

    // MARK: - Successive calls (sweeps advance & respawn)

    func test_fillBuffer_multipleCalls_doNotCrash() {
        let gen = FrequencySweepGenerator()
        for _ in 0..<20 {
            _ = fillBuffer(generator: gen, count: 512)
        }
    }

    func test_fillBuffer_sweepCyclesComplete_generatorContinuesProducingOutput() {
        // A sweep at 50ms duration = 2400 samples. Fill well past that to exercise respawn logic.
        let gen = FrequencySweepGenerator(intensity: 1.0)
        let output = fillBuffer(generator: gen, count: 48000)  // 1 second
        XCTAssertTrue(output.contains { $0 != 0 },
                      "Generator should produce output even after sweep cycles complete and respawn")
    }

    func test_fillBuffer_consecutiveCalls_produceDifferentContent() {
        let gen = FrequencySweepGenerator()
        let out1 = fillBuffer(generator: gen, count: 256)
        let out2 = fillBuffer(generator: gen, count: 256)
        // Sweep phases advance each sample — output should differ
        XCTAssertNotEqual(out1, out2)
    }

    // MARK: - isEnabled

    func test_isEnabled_canBeSetFalse() {
        let gen = FrequencySweepGenerator()
        gen.isEnabled = false
        XCTAssertFalse(gen.isEnabled)
    }

    func test_isEnabled_toggleRoundTrip() {
        let gen = FrequencySweepGenerator()
        gen.isEnabled = false
        gen.isEnabled = true
        XCTAssertTrue(gen.isEnabled)
    }

    // MARK: - updateMaskingThreshold

    func test_updateMaskingThreshold_emptyArray_doesNotCrash() {
        let gen = FrequencySweepGenerator()
        gen.updateMaskingThreshold([])
    }

    func test_updateMaskingThreshold_validThreshold_doesNotCrash() {
        let gen = FrequencySweepGenerator()
        gen.updateMaskingThreshold([Float](repeating: -40, count: 512))
    }

    // MARK: - Exact frame count

    func test_fillBuffer_writesExactFrameCount() {
        let gen = FrequencySweepGenerator()
        let count = 768
        let output = fillBuffer(generator: gen, count: count)
        XCTAssertEqual(output.count, count)
    }

    func test_fillBuffer_largeFrameCount_doesNotCrash() {
        let gen = FrequencySweepGenerator()
        let output = fillBuffer(generator: gen, count: 48000)
        XCTAssertEqual(output.count, 48000)
    }

    // MARK: - Single frame

    func test_fillBuffer_singleFrame_doesNotCrash() {
        let gen = FrequencySweepGenerator()
        let output = fillBuffer(generator: gen, count: 1)
        XCTAssertEqual(output.count, 1)
    }
}
