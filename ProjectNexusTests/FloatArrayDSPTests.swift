import XCTest
@testable import ProjectNexus

final class FloatArrayDSPTests: XCTestCase {

    // MARK: - rms()

    func test_rms_emptyArray_returnsZero() {
        let arr: [Float] = []
        XCTAssertEqual(arr.rms(), 0)
    }

    func test_rms_allZeros_returnsZero() {
        let arr = [Float](repeating: 0, count: 256)
        XCTAssertEqual(arr.rms(), 0, accuracy: 1e-6)
    }

    func test_rms_uniformOnes_returnsOne() {
        let arr = [Float](repeating: 1.0, count: 256)
        XCTAssertEqual(arr.rms(), 1.0, accuracy: 1e-5)
    }

    func test_rms_uniformHalf_returnsHalf() {
        let arr = [Float](repeating: 0.5, count: 512)
        XCTAssertEqual(arr.rms(), 0.5, accuracy: 1e-5)
    }

    func test_rms_symmetricSignal_isCorrect() {
        // +1 and -1 alternating → RMS = 1
        let arr: [Float] = (0..<256).map { Float($0 % 2 == 0 ? 1 : -1) }
        XCTAssertEqual(arr.rms(), 1.0, accuracy: 1e-5)
    }

    // MARK: - peak()

    func test_peak_emptyArray_returnsZero() {
        let arr: [Float] = []
        XCTAssertEqual(arr.peak(), 0)
    }

    func test_peak_allZeros_returnsZero() {
        let arr = [Float](repeating: 0, count: 256)
        XCTAssertEqual(arr.peak(), 0, accuracy: 1e-6)
    }

    func test_peak_returnsMaxMagnitude() {
        var arr: [Float] = [0.1, -0.9, 0.5, 0.3]
        // vDSP_maxmgv returns max of absolute values
        XCTAssertEqual(arr.peak(), 0.9, accuracy: 1e-5)
    }

    func test_peak_singleElement() {
        let arr: [Float] = [0.42]
        XCTAssertEqual(arr.peak(), 0.42, accuracy: 1e-5)
    }

    // MARK: - scaled(by:)

    func test_scaled_byZero_returnsAllZeros() {
        let arr: [Float] = [1.0, 2.0, 3.0]
        let result = arr.scaled(by: 0)
        XCTAssertTrue(result.allSatisfy { $0 == 0 })
    }

    func test_scaled_byOne_returnsOriginal() {
        let arr: [Float] = [1.0, -0.5, 0.25]
        let result = arr.scaled(by: 1.0)
        for (a, b) in zip(arr, result) {
            XCTAssertEqual(a, b, accuracy: 1e-6)
        }
    }

    func test_scaled_byTwo_doublesValues() {
        let arr: [Float] = [1.0, 2.0, 3.0]
        let result = arr.scaled(by: 2.0)
        XCTAssertEqual(result, [2.0, 4.0, 6.0])
    }

    func test_scaled_preservesCount() {
        let arr = [Float](repeating: 0.5, count: 100)
        XCTAssertEqual(arr.scaled(by: 2).count, 100)
    }

    // MARK: - added(to:)

    func test_added_equalLengthArrays() {
        let a: [Float] = [1.0, 2.0, 3.0]
        let b: [Float] = [0.5, 0.5, 0.5]
        let result = a.added(to: b)
        XCTAssertEqual(result, [1.5, 2.5, 3.5])
    }

    func test_added_truncatesToShorterLength() {
        let a: [Float] = [1.0, 2.0, 3.0, 4.0]
        let b: [Float] = [1.0, 1.0]
        let result = a.added(to: b)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, [2.0, 3.0])
    }

    func test_added_toZeroArray_returnsOriginal() {
        let a: [Float] = [1.0, -1.0, 0.5]
        let zeros = [Float](repeating: 0, count: 3)
        let result = a.added(to: zeros)
        for (x, y) in zip(a, result) {
            XCTAssertEqual(x, y, accuracy: 1e-6)
        }
    }

    // MARK: - multiplied(by:)

    func test_multiplied_byOne_returnsOriginal() {
        let a: [Float] = [2.0, 3.0, -1.0]
        let ones = [Float](repeating: 1.0, count: 3)
        let result = a.multiplied(by: ones)
        for (x, y) in zip(a, result) {
            XCTAssertEqual(x, y, accuracy: 1e-6)
        }
    }

    func test_multiplied_byZero_returnsAllZeros() {
        let a: [Float] = [2.0, 3.0, -1.0]
        let zeros = [Float](repeating: 0, count: 3)
        let result = a.multiplied(by: zeros)
        XCTAssertTrue(result.allSatisfy { $0 == 0 })
    }

    func test_multiplied_truncatesToShorterLength() {
        let a: [Float] = [1.0, 2.0, 3.0, 4.0]
        let b: [Float] = [2.0, 2.0]
        let result = a.multiplied(by: b)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result, [2.0, 4.0])
    }

    // MARK: - toDecibels(reference:)

    func test_toDecibels_preservesCount() {
        let arr: [Float] = [0.1, 0.5, 1.0, 2.0]
        XCTAssertEqual(arr.toDecibels().count, arr.count)
    }

    func test_toDecibels_referenceOne_oneValue_isZero() {
        // 20 * log10(1.0) = 0 dB using power flag (vDSP_vdbcon with flag=1 = 10*log10)
        let arr: [Float] = [1.0]
        let result = arr.toDecibels(reference: 1.0)
        // vDSP_vdbcon with flag=1 computes 10*log10(x/ref), so log10(1/1)*10 = 0
        XCTAssertEqual(result[0], 0, accuracy: 0.01)
    }

    // MARK: - hannWindowed()

    func test_hannWindowed_preservesCount() {
        let arr = [Float](repeating: 1.0, count: 256)
        XCTAssertEqual(arr.hannWindowed().count, 256)
    }

    func test_hannWindowed_firstSampleNearZero() {
        let arr = [Float](repeating: 1.0, count: 512)
        let windowed = arr.hannWindowed()
        XCTAssertEqual(windowed[0], 0, accuracy: 0.01)
    }

    func test_hannWindowed_allNonNegative_whenInputPositive() {
        let arr = [Float](repeating: 1.0, count: 256)
        let windowed = arr.hannWindowed()
        XCTAssertTrue(windowed.allSatisfy { $0 >= 0 })
    }

    func test_hannWindowed_reducesEnergy() {
        let arr = [Float](repeating: 1.0, count: 512)
        let windowed = arr.hannWindowed()
        // Hann window reduces total energy
        let originalEnergy = arr.reduce(0) { $0 + $1 * $1 }
        let windowedEnergy = windowed.reduce(0) { $0 + $1 * $1 }
        XCTAssertLessThan(windowedEnergy, originalEnergy)
    }
}
