import XCTest
@testable import ProjectNexus

final class DSPUtilitiesTests: XCTestCase {

    // MARK: - frequencyToBark

    func test_frequencyToBark_zeroHz_returnsZero() {
        let result = DSPUtilities.frequencyToBark(0)
        XCTAssertEqual(result, 0, accuracy: 0.001)
    }

    func test_frequencyToBark_1000Hz_returnsApproximately8point5() {
        // The Bark scale value for 1 kHz is approximately 8.5
        let result = DSPUtilities.frequencyToBark(1000)
        XCTAssertEqual(result, 8.5, accuracy: 0.5)
    }

    func test_frequencyToBark_isMonotonicallyIncreasing() {
        let freqs: [Float] = [100, 500, 1000, 2000, 4000, 8000]
        let barks = freqs.map { DSPUtilities.frequencyToBark($0) }
        for i in 1..<barks.count {
            XCTAssertGreaterThan(barks[i], barks[i - 1],
                "Bark scale should be monotonically increasing. Failed at index \(i)")
        }
    }

    // MARK: - barkToFrequency

    func test_barkToFrequency_zeroBarks_returnsZero() {
        let result = DSPUtilities.barkToFrequency(0)
        XCTAssertEqual(result, 0, accuracy: 0.01)
    }

    func test_barkToFrequency_isMonotonicallyIncreasing() {
        let barks: [Float] = [1, 3, 5, 8, 12, 16]
        let freqs = barks.map { DSPUtilities.barkToFrequency($0) }
        for i in 1..<freqs.count {
            XCTAssertGreaterThan(freqs[i], freqs[i - 1],
                "barkToFrequency should be monotonically increasing. Failed at index \(i)")
        }
    }

    // MARK: - frequencyToBin

    func test_frequencyToBin_zeroHz_returnsZero() {
        let bin = DSPUtilities.frequencyToBin(0, sampleRate: 44100, fftSize: 1024)
        XCTAssertEqual(bin, 0)
    }

    func test_frequencyToBin_neverExceedsHalfFFT() {
        // A very high frequency should clamp to fftSize/2 - 1
        let bin = DSPUtilities.frequencyToBin(100_000, sampleRate: 44100, fftSize: 1024)
        XCTAssertEqual(bin, 511) // fftSize/2 - 1
    }

    func test_frequencyToBin_nyquist_returnsHalfFFTMinusOne() {
        let nyquist: Float = 22050
        let bin = DSPUtilities.frequencyToBin(nyquist, sampleRate: 44100, fftSize: 1024)
        XCTAssertEqual(bin, 511)
    }

    func test_frequencyToBin_1kHz_at44100_1024() {
        // bin = round(1000 * 1024 / 44100) ≈ 23
        let bin = DSPUtilities.frequencyToBin(1000, sampleRate: 44100, fftSize: 1024)
        XCTAssertEqual(bin, 23)
    }

    // MARK: - binToFrequency

    func test_binToFrequency_zeroBin_returnsZero() {
        let freq = DSPUtilities.binToFrequency(0, sampleRate: 44100, fftSize: 1024)
        XCTAssertEqual(freq, 0, accuracy: 0.01)
    }

    func test_binToFrequency_roundTrip() {
        let originalFreq: Float = 1000
        let bin = DSPUtilities.frequencyToBin(originalFreq, sampleRate: 44100, fftSize: 1024)
        let recoveredFreq = DSPUtilities.binToFrequency(bin, sampleRate: 44100, fftSize: 1024)
        // Should be within one bin width (~43 Hz at 44100/1024)
        XCTAssertEqual(recoveredFreq, originalFreq, accuracy: 50)
    }

    // MARK: - generateWhiteNoise

    func test_generateWhiteNoise_returnsRequestedCount() {
        let noise = DSPUtilities.generateWhiteNoise(count: 512)
        XCTAssertEqual(noise.count, 512)
    }

    func test_generateWhiteNoise_valuesWithinRange() {
        let noise = DSPUtilities.generateWhiteNoise(count: 4096)
        for sample in noise {
            XCTAssertTrue(sample >= -1.0 && sample <= 1.0,
                "Noise sample \(sample) out of [-1, 1] range")
        }
    }

    func test_generateWhiteNoise_notAllZero() {
        let noise = DSPUtilities.generateWhiteNoise(count: 64)
        XCTAssertFalse(noise.allSatisfy { $0 == 0 })
    }

    // MARK: - generateHannWindow

    func test_generateHannWindow_returnsRequestedSize() {
        let window = DSPUtilities.generateHannWindow(size: 256)
        XCTAssertEqual(window.count, 256)
    }

    func test_generateHannWindow_endsNearZero() {
        let window = DSPUtilities.generateHannWindow(size: 512)
        XCTAssertEqual(window.first!, 0, accuracy: 0.01)
    }

    func test_generateHannWindow_peakNearCenter() {
        let n = 512
        let window = DSPUtilities.generateHannWindow(size: n)
        let centerVal = window[n / 2]
        for (i, val) in window.enumerated() {
            XCTAssertLessThanOrEqual(val, centerVal + 0.01,
                "Value at index \(i) exceeds center peak")
        }
    }

    func test_generateHannWindow_allNonNegative() {
        let window = DSPUtilities.generateHannWindow(size: 256)
        XCTAssertTrue(window.allSatisfy { $0 >= 0 })
    }

    // MARK: - barkBandEdges

    func test_barkBandEdges_count() {
        // Should have 25 edges covering 0–15500 Hz
        XCTAssertEqual(DSPUtilities.barkBandEdges.count, 25)
    }

    func test_barkBandEdges_isAscending() {
        let edges = DSPUtilities.barkBandEdges
        for i in 1..<edges.count {
            XCTAssertGreaterThan(edges[i], edges[i - 1],
                "Bark band edges should be ascending. Failed at index \(i)")
        }
    }

    func test_barkBandEdges_startsAtAudibleFrequency() {
        XCTAssertGreaterThanOrEqual(DSPUtilities.barkBandEdges.first!, 20)
    }

    // MARK: - fftSize constants

    func test_fftSize_isPowerOfTwo() {
        let size = DSPUtilities.fftSize
        XCTAssertTrue((size & (size - 1)) == 0, "fftSize must be a power of two")
    }

    func test_halfFFTSize_isHalfOfFFTSize() {
        XCTAssertEqual(DSPUtilities.halfFFTSize, DSPUtilities.fftSize / 2)
    }
}
