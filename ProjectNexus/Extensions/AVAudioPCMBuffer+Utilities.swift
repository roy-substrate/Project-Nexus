import AVFoundation
import Accelerate

extension AVAudioPCMBuffer {
    var rmsLevel: Float {
        guard let channelData = floatChannelData?[0] else { return -160 }
        let count = Int(frameLength)
        guard count > 0 else { return -160 }

        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(count))
        let db = 10 * log10f(max(rms, 1e-10))
        return db
    }

    var peakLevel: Float {
        guard let channelData = floatChannelData?[0] else { return -160 }
        let count = Int(frameLength)
        guard count > 0 else { return -160 }

        var peak: Float = 0
        vDSP_maxmgv(channelData, 1, &peak, vDSP_Length(count))
        let db = 20 * log10f(max(peak, 1e-10))
        return db
    }

    static func create(format: AVAudioFormat, frameCapacity: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            return nil
        }
        buffer.frameLength = frameCapacity
        return buffer
    }

    func copyFrom(_ source: AVAudioPCMBuffer, count: AVAudioFrameCount) {
        guard let destData = floatChannelData?[0],
              let srcData = source.floatChannelData?[0] else { return }
        let framesToCopy = min(count, min(frameCapacity, source.frameLength))
        memcpy(destData, srcData, Int(framesToCopy) * MemoryLayout<Float>.size)
        frameLength = framesToCopy
    }

    func mixWith(_ other: AVAudioPCMBuffer, gain: Float = 1.0) {
        guard let destData = floatChannelData?[0],
              let srcData = other.floatChannelData?[0] else { return }
        let count = min(frameLength, other.frameLength)
        var g = gain
        vDSP_vsma(srcData, 1, &g, destData, 1, destData, 1, vDSP_Length(count))
    }

    func applyGain(_ gain: Float) {
        guard let data = floatChannelData?[0] else { return }
        var g = gain
        vDSP_vsmul(data, 1, &g, data, 1, vDSP_Length(frameLength))
    }

    func clear() {
        guard let data = floatChannelData?[0] else { return }
        vDSP_vclr(data, 1, vDSP_Length(frameLength))
    }
}
