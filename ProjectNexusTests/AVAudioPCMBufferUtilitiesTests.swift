import XCTest
#if canImport(AVFoundation)
import AVFoundation
@testable import ProjectNexus

final class AVAudioPCMBufferUtilitiesTests: XCTestCase {

    private var format: AVAudioFormat!

    override func setUp() {
        super.setUp()
        format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
    }

    // MARK: - create(format:frameCapacity:)

    func test_create_returnsBuffer_withCorrectFrameLength() {
        let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 512)
        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer?.frameLength, 512)
        XCTAssertEqual(buffer?.frameCapacity, 512)
    }

    func test_create_bufferHasNonNilFloatChannelData() {
        let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 256)
        XCTAssertNotNil(buffer?.floatChannelData?[0])
    }

    // MARK: - rmsLevel

    func test_rmsLevel_silentBuffer_returnsLowDb() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 1024) else {
            return XCTFail("Could not create buffer")
        }
        buffer.clear()
        XCTAssertLessThan(buffer.rmsLevel, -100, "Silent buffer RMS should be very low (dB)")
    }

    func test_rmsLevel_fullScaleSine_isNearZeroDb() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 1024) else {
            return XCTFail("Could not create buffer")
        }
        guard let data = buffer.floatChannelData?[0] else { return XCTFail() }
        let n = 1024
        for i in 0..<n {
            data[i] = sin(2 * Float.pi * 440 * Float(i) / 48000)
        }
        // RMS of a full-scale sine is 1/sqrt(2) ≈ -3 dB
        XCTAssertEqual(buffer.rmsLevel, -3.0, accuracy: 0.5)
    }

    // MARK: - peakLevel

    func test_peakLevel_silentBuffer_returnsLowDb() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 512) else {
            return XCTFail("Could not create buffer")
        }
        buffer.clear()
        XCTAssertLessThan(buffer.peakLevel, -100)
    }

    func test_peakLevel_fullScaleSignal_isNearZeroDb() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 64) else {
            return XCTFail("Could not create buffer")
        }
        guard let data = buffer.floatChannelData?[0] else { return XCTFail() }
        data[0] = 1.0
        XCTAssertEqual(buffer.peakLevel, 0.0, accuracy: 0.01)
    }

    // MARK: - clear()

    func test_clear_zeroesSamples() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 256) else {
            return XCTFail("Could not create buffer")
        }
        guard let data = buffer.floatChannelData?[0] else { return XCTFail() }
        for i in 0..<256 { data[i] = 1.0 }
        buffer.clear()
        for i in 0..<256 { XCTAssertEqual(data[i], 0.0, accuracy: 1e-7) }
    }

    // MARK: - applyGain(_:)

    func test_applyGain_halvesAmplitude() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 64) else {
            return XCTFail("Could not create buffer")
        }
        guard let data = buffer.floatChannelData?[0] else { return XCTFail() }
        for i in 0..<64 { data[i] = 1.0 }
        buffer.applyGain(0.5)
        for i in 0..<64 { XCTAssertEqual(data[i], 0.5, accuracy: 1e-6) }
    }

    func test_applyGain_zero_silences() {
        guard let buffer = AVAudioPCMBuffer.create(format: format, frameCapacity: 64) else {
            return XCTFail("Could not create buffer")
        }
        guard let data = buffer.floatChannelData?[0] else { return XCTFail() }
        for i in 0..<64 { data[i] = 0.8 }
        buffer.applyGain(0.0)
        for i in 0..<64 { XCTAssertEqual(data[i], 0.0, accuracy: 1e-7) }
    }

    // MARK: - copyFrom(_:count:)

    func test_copyFrom_copiesSamples() {
        guard
            let src = AVAudioPCMBuffer.create(format: format, frameCapacity: 128),
            let dst = AVAudioPCMBuffer.create(format: format, frameCapacity: 128)
        else { return XCTFail("Could not create buffers") }

        guard let srcData = src.floatChannelData?[0],
              let dstData = dst.floatChannelData?[0] else { return XCTFail() }

        for i in 0..<128 { srcData[i] = Float(i) * 0.01 }
        dst.copyFrom(src, count: 64)

        XCTAssertEqual(dst.frameLength, 64)
        for i in 0..<64 { XCTAssertEqual(dstData[i], Float(i) * 0.01, accuracy: 1e-6) }
    }

    // MARK: - mixWith(_:gain:)

    func test_mixWith_addsScaledSamples() {
        guard
            let a = AVAudioPCMBuffer.create(format: format, frameCapacity: 64),
            let b = AVAudioPCMBuffer.create(format: format, frameCapacity: 64)
        else { return XCTFail("Could not create buffers") }

        guard let aData = a.floatChannelData?[0],
              let bData = b.floatChannelData?[0] else { return XCTFail() }

        for i in 0..<64 { aData[i] = 0.5; bData[i] = 1.0 }
        a.mixWith(b, gain: 0.5)  // a[i] = 0.5 + 1.0 * 0.5 = 1.0

        for i in 0..<64 { XCTAssertEqual(aData[i], 1.0, accuracy: 1e-5) }
    }
}
#endif
