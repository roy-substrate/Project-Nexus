import XCTest
@testable import ProjectNexus

final class CodecSimulatorTests: XCTestCase {

    // MARK: - Init / lifecycle

    func test_init_doesNotThrow_forAllTargets() {
        for target in CodecTarget.allCases {
            XCTAssertNoThrow(try CodecSimulator(codecTarget: target))
        }
    }

    func test_init_noneTarget_envelopeIsAllOnes() throws {
        let sim = try CodecSimulator(codecTarget: .none, fftSize: 64, sampleRate: 48000)
        var spectrum = [Float](repeating: 1.0, count: 32)
        sim.applyToSpectrum(&spectrum)
        // .none early-returns — spectrum should be unchanged
        XCTAssertTrue(spectrum.allSatisfy { $0 == 1.0 })
    }

    // MARK: - applyToSpectrum

    func test_applyToSpectrum_opus32k_attenuatesHighFrequencies() throws {
        let sim = try CodecSimulator(codecTarget: .opus32k, fftSize: 1024, sampleRate: 48000)
        // Bin for ~12 kHz should be heavily attenuated vs passband bin (~1 kHz)
        var spectrum = [Float](repeating: 1.0, count: 512)
        sim.applyToSpectrum(&spectrum)

        let passbandBin = DSPUtilities.frequencyToBin(1000, sampleRate: 48000, fftSize: 1024)
        let highFreqBin = DSPUtilities.frequencyToBin(12000, sampleRate: 48000, fftSize: 1024)

        XCTAssertGreaterThan(spectrum[passbandBin], spectrum[highFreqBin],
            "Passband should be preserved more than high frequencies for opus32k")
    }

    func test_applyToSpectrum_opus128k_nearTransparentAtMidRange() throws {
        let sim = try CodecSimulator(codecTarget: .opus128k, fftSize: 1024, sampleRate: 48000)
        var spectrum = [Float](repeating: 1.0, count: 512)
        sim.applyToSpectrum(&spectrum)

        let bin1k = DSPUtilities.frequencyToBin(1000, sampleRate: 48000, fftSize: 1024)
        XCTAssertEqual(spectrum[bin1k], 1.0, accuracy: 0.01,
            "opus128k should be near-transparent at 1 kHz")
    }

    func test_applyToSpectrum_doesNotModifySpectrum_whenTargetIsNone() throws {
        let sim = try CodecSimulator(codecTarget: .none)
        var spectrum = [Float](repeating: 0.5, count: 512)
        sim.applyToSpectrum(&spectrum)
        XCTAssertTrue(spectrum.allSatisfy { $0 == 0.5 })
    }

    func test_applyToSpectrum_outputLengthMatchesInput() throws {
        let sim = try CodecSimulator(codecTarget: .opus64k, fftSize: 1024, sampleRate: 48000)
        var spectrum = [Float](repeating: 1.0, count: 256)
        sim.applyToSpectrum(&spectrum)
        XCTAssertEqual(spectrum.count, 256)
    }

    // MARK: - applyToSignal

    func test_applyToSignal_outputLengthMatchesInput() throws {
        let sim = try CodecSimulator(codecTarget: .opus64k, fftSize: 64, sampleRate: 48000)
        var signal = [Float](repeating: 0.5, count: 256)
        sim.applyToSignal(&signal)
        XCTAssertEqual(signal.count, 256)
    }

    func test_applyToSignal_noopWhenShorterThanFFTSize() throws {
        let sim = try CodecSimulator(codecTarget: .opus64k, fftSize: 1024, sampleRate: 48000)
        var signal = [Float](repeating: 0.5, count: 512)  // shorter than fftSize
        sim.applyToSignal(&signal)
        XCTAssertTrue(signal.allSatisfy { $0 == 0.5 }, "Signal shorter than fftSize should not be modified")
    }

    func test_applyToSignal_noneTarget_isNoop() throws {
        let sim = try CodecSimulator(codecTarget: .none, fftSize: 64, sampleRate: 48000)
        let original = (0..<256).map { Float($0) * 0.001 }
        var signal = original
        sim.applyToSignal(&signal)
        for i in 0..<signal.count {
            XCTAssertEqual(signal[i], original[i], accuracy: 1e-5)
        }
    }

    func test_applyToSignal_opus32k_vs_opus128k_differ() throws {
        let signal32k: [Float] = (0..<1024).map { Float.random(in: -0.5...0.5) }
        var s32 = signal32k
        var s128 = signal32k

        try CodecSimulator(codecTarget: .opus32k,  fftSize: 64, sampleRate: 48000).applyToSignal(&s32)
        try CodecSimulator(codecTarget: .opus128k, fftSize: 64, sampleRate: 48000).applyToSignal(&s128)

        let diff = zip(s32, s128).reduce(Float(0)) { acc, p in acc + abs(p.0 - p.1) }
        XCTAssertGreaterThan(diff, 0.001, "opus32k and opus128k should produce measurably different output")
    }
}
