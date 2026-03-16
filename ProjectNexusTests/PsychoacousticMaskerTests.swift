import XCTest
@testable import ProjectNexus

final class PsychoacousticMaskerTests: XCTestCase {

    private let fftSize = 1024
    private let sampleRate: Float = 48000

    // MARK: - Helpers

    /// Returns a flat spectrum at `dBLevel` across all bins.
    private func flatSpectrum(dB: Float, count: Int) -> [Float] {
        [Float](repeating: dB, count: count)
    }

    /// Returns a spike spectrum: one loud bin at `binIndex`, everything else silent.
    private func spikeSpectrum(loudBin: Int, dB: Float, count: Int) -> [Float] {
        var spectrum = [Float](repeating: -100, count: count)
        if loudBin < count { spectrum[loudBin] = dB }
        return spectrum
    }

    // MARK: - Initialisation / default state

    func test_init_defaultThresholdSize_equalsHalfFFTSize() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        let threshold = masker.getCurrentThreshold()
        XCTAssertEqual(threshold.count, fftSize / 2)
    }

    func test_init_defaultThresholdIsAllSilence() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        let threshold = masker.getCurrentThreshold()
        XCTAssertTrue(threshold.allSatisfy { $0 == -60 },
                      "Default masking threshold should be -60 dB (silence) before any input")
    }

    func test_init_customFFTSize_thresholdHasCorrectSize() {
        let masker = PsychoacousticMasker(fftSize: 2048, sampleRate: sampleRate)
        let threshold = masker.getCurrentThreshold()
        XCTAssertEqual(threshold.count, 1024)
    }

    // MARK: - computeThreshold: guard conditions

    func test_computeThreshold_tooShortSpectrum_isIgnored() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Pass a spectrum shorter than fftSize/2 — should be ignored, threshold unchanged
        masker.computeThreshold(from: [Float](repeating: -10, count: 10))
        let threshold = masker.getCurrentThreshold()
        XCTAssertTrue(threshold.allSatisfy { $0 == -60 },
                      "Short spectrum should be ignored; threshold should remain default")
    }

    func test_computeThreshold_emptySpectrum_isIgnored() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: [])
        let threshold = masker.getCurrentThreshold()
        XCTAssertTrue(threshold.allSatisfy { $0 == -60 })
    }

    func test_computeThreshold_exactMinimumSize_doesNotCrash() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: [Float](repeating: -60, count: fftSize / 2))
    }

    // MARK: - computeThreshold: silent input

    func test_computeThreshold_silentSpectrum_thresholdRemainsLow() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: flatSpectrum(dB: -100, count: fftSize / 2))
        let threshold = masker.getCurrentThreshold()
        // With a very quiet input, threshold should not rise above -30 dB anywhere
        let maxThreshold = threshold.max() ?? -100
        XCTAssertLessThanOrEqual(maxThreshold, -30,
                                 "Masking threshold should remain low for a silent input")
    }

    // MARK: - computeThreshold: loud input raises threshold

    func test_computeThreshold_loudFlatSpectrum_raisesThresholdAboveDefault() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: flatSpectrum(dB: 0, count: fftSize / 2))
        let threshold = masker.getCurrentThreshold()
        // A 0 dB flat input should raise the masking threshold well above -60 dB
        let maxThreshold = threshold.max() ?? -100
        XCTAssertGreaterThan(maxThreshold, -60,
                             "A loud flat spectrum should raise the masking threshold above default")
    }

    func test_computeThreshold_loudSpike_raisesThresholdNearSpike() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Loud spike at bin 50 (~2.3 kHz at 48kHz/1024 = ~46.9 Hz/bin)
        let spike = spikeSpectrum(loudBin: 50, dB: 0, count: fftSize / 2)
        masker.computeThreshold(from: spike)
        let threshold = masker.getCurrentThreshold()
        let maxThreshold = threshold.max() ?? -100
        XCTAssertGreaterThan(maxThreshold, -60,
                             "A loud spike should raise the masking threshold in nearby bins")
    }

    func test_computeThreshold_updatesThreshold() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        let before = masker.getCurrentThreshold()
        masker.computeThreshold(from: flatSpectrum(dB: 0, count: fftSize / 2))
        let after = masker.getCurrentThreshold()
        XCTAssertNotEqual(before, after,
                          "computeThreshold should update the stored masking threshold")
    }

    // MARK: - computeThreshold: spreading function

    func test_computeThreshold_spreadingFunctionIsApplied() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Loud spike at a mid-frequency bin
        let spike = spikeSpectrum(loudBin: 100, dB: 0, count: fftSize / 2)
        masker.computeThreshold(from: spike)
        let threshold = masker.getCurrentThreshold()

        // Bins adjacent to the spike should also have elevated threshold due to spreading
        let adjacentBinsElevated = (90...110).map { threshold[$0] }.contains { $0 > -60 }
        XCTAssertTrue(adjacentBinsElevated,
                      "Spreading function should elevate threshold in bins adjacent to the masker")
    }

    func test_computeThreshold_upwardSpreadIsWeakerThanDownward() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Spike at bin 200 — check that bins below 200 have higher threshold than bins above 200
        let spike = spikeSpectrum(loudBin: 200, dB: 0, count: fftSize / 2)
        masker.computeThreshold(from: spike)
        let threshold = masker.getCurrentThreshold()

        // Bin just below spike (180) should have higher threshold than bin just above (220)
        // because downward spread is stronger than upward spread in this model
        XCTAssertGreaterThan(threshold[180], threshold[220],
                             "Downward spread (to lower bins) should be stronger than upward spread")
    }

    // MARK: - getMaxAmplitude

    func test_getMaxAmplitude_defaultState_returnsSmallAmplitude() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Default threshold is -60 dB → amplitude = 10^(-60/20) = 0.001
        let amplitude = masker.getMaxAmplitude(forBin: 100)
        XCTAssertEqual(amplitude, powf(10.0, -60.0 / 20.0), accuracy: 1e-5)
    }

    func test_getMaxAmplitude_afterLoudInput_returnsHigherAmplitude() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: flatSpectrum(dB: 0, count: fftSize / 2))
        let amplitude = masker.getMaxAmplitude(forBin: 100)
        let defaultAmplitude = powf(10.0, -60.0 / 20.0)
        XCTAssertGreaterThan(amplitude, defaultAmplitude,
                             "Max amplitude should increase after a loud input is processed")
    }

    func test_getMaxAmplitude_bin0_doesNotCrash() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        _ = masker.getMaxAmplitude(forBin: 0)
    }

    func test_getMaxAmplitude_lastBin_doesNotCrash() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        _ = masker.getMaxAmplitude(forBin: fftSize / 2 - 1)
    }

    func test_getMaxAmplitude_outOfBoundsBin_clampsToLastBin() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        // Out-of-bounds bin is clamped in implementation; should not crash
        _ = masker.getMaxAmplitude(forBin: 9999)
    }

    // MARK: - Thread safety

    func test_computeThreshold_andGetCurrentThreshold_concurrentAccess_doesNotCrash() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        let spectrum = flatSpectrum(dB: -20, count: fftSize / 2)
        let exp = expectation(description: "concurrent access")
        exp.expectedFulfillmentCount = 2

        DispatchQueue.global().async {
            for _ in 0..<100 { masker.computeThreshold(from: spectrum) }
            exp.fulfill()
        }
        DispatchQueue.global().async {
            for _ in 0..<100 { _ = masker.getCurrentThreshold() }
            exp.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: - getCurrentThreshold returns a copy

    func test_getCurrentThreshold_returnsCopyNotReference() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        var t1 = masker.getCurrentThreshold()
        t1[0] = 999  // mutate caller's copy
        let t2 = masker.getCurrentThreshold()
        XCTAssertNotEqual(t2[0], 999,
                          "getCurrentThreshold should return a copy; mutating it must not affect internal state")
    }

    // MARK: - Multiple computeThreshold calls

    func test_computeThreshold_calledMultipleTimes_alwaysUpdates() {
        let masker = PsychoacousticMasker(fftSize: fftSize, sampleRate: sampleRate)
        masker.computeThreshold(from: flatSpectrum(dB: 0, count: fftSize / 2))
        let after1 = masker.getCurrentThreshold().max() ?? -100

        masker.computeThreshold(from: flatSpectrum(dB: -100, count: fftSize / 2))
        let after2 = masker.getCurrentThreshold().max() ?? -100

        XCTAssertGreaterThan(after1, after2,
                             "Threshold should decrease when switching from loud to silent input")
    }
}
