import AVFoundation
import Accelerate
import os

final class MicCaptureNode {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "MicCapture")
    private var inputTap: AVAudioNodeTapBlock?

    private let fftSize = 1024
    private var analysisBuffer: [Float]
    private var spectrumOutput: [Float]
    private let analysisQueue = DispatchQueue(label: "com.nexus.micanalysis", qos: .userInteractive)

    var onSpectrumUpdate: (([Float], Float, Float) -> Void)?

    init() {
        analysisBuffer = [Float](repeating: 0, count: fftSize)
        spectrumOutput = [Float](repeating: -60, count: fftSize / 2)
    }

    func installTap(on node: AVAudioNode, bus: AVAudioNodeBus = 0, bufferSize: AVAudioFrameCount = 1024) {
        let format = node.outputFormat(forBus: bus)
        guard format.sampleRate > 0 else {
            logger.warning("Invalid format for mic capture")
            return
        }

        node.installTap(onBus: bus, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            self?.processBuffer(buffer)
        }
        logger.info("Mic tap installed: \(format.sampleRate)Hz, \(bufferSize) frames")
    }

    func removeTap(from node: AVAudioNode, bus: AVAudioNodeBus = 0) {
        node.removeTap(onBus: bus)
        logger.info("Mic tap removed")
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        let rms = buffer.rmsLevel
        let peak = buffer.peakLevel

        analysisQueue.async { [weak self] in
            guard let self else { return }

            let count = min(frameCount, self.fftSize)
            self.analysisBuffer.withUnsafeMutableBufferPointer { dest in
                dest.baseAddress?.update(from: channelData, count: count)
            }

            let spectrum = self.computeSpectrum()
            self.onSpectrumUpdate?(spectrum, rms, peak)
        }
    }

    private func computeSpectrum() -> [Float] {
        let n = fftSize
        let halfN = n / 2
        let log2n = vDSP_Length(log2(Float(n)))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return [Float](repeating: -60, count: halfN)
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var windowed = analysisBuffer.hannWindowed()
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        windowed.withUnsafeMutableBufferPointer { windowedPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(
                        realp: realPtr.baseAddress!,
                        imagp: imagPtr.baseAddress!
                    )
                    windowedPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                    }
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                    var magnitudes = [Float](repeating: 0, count: halfN)
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfN))

                    var scaleFactor = Float(1.0 / Float(n))
                    vDSP_vsmul(magnitudes, 1, &scaleFactor, &magnitudes, 1, vDSP_Length(halfN))

                    var ref = Float(1.0)
                    vDSP_vdbcon(magnitudes, 1, &ref, &magnitudes, 1, vDSP_Length(halfN), 1)

                    self.spectrumOutput = magnitudes
                }
            }
        }

        return spectrumOutput
    }
}
