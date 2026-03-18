import AVFoundation
import Accelerate
import os

final class MicCaptureNode {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "MicCapture")

    private let fftSize = 1024

    // Created once and reused for every computeSpectrum() call.
    // Creating/destroying an FFTSetup is expensive (~microseconds of allocation
    // overhead) and was previously happening ~43 times per second.
    private let fftSetup: FFTSetup

    private var analysisBuffer: [Float]
    private var spectrumOutput: [Float]

    // `.utility` is appropriate here: spectrum analysis is not on the critical path
    // and should not compete with the real-time audio render thread.
    private let analysisQueue = DispatchQueue(label: "com.nexus.micanalysis", qos: .utility)

    var onSpectrumUpdate: (([Float], Float, Float) -> Void)?
    /// Called on the analysis queue with each raw PCM buffer.
    /// Use this to feed ASREffectivenessService without a second AVAudioEngine.
    var onRawBuffer: ((AVAudioPCMBuffer) -> Void)?

    init() throws {
        analysisBuffer = [Float](repeating: 0, count: fftSize)
        spectrumOutput = [Float](repeating: -60, count: fftSize / 2)

        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            throw MicCaptureError.fftSetupFailed
        }
        fftSetup = setup
    }

    enum MicCaptureError: LocalizedError {
        case fftSetupFailed
        var errorDescription: String? {
            "Audio analysis could not be initialised (FFT setup failed). Try restarting the app."
        }
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func installTap(on node: AVAudioNode, bus: AVAudioNodeBus = 0, bufferSize: AVAudioFrameCount = 1024) {
        let format = node.outputFormat(forBus: bus)
        guard format.sampleRate > 0 else {
            logger.warning("Invalid format for mic capture")
            return
        }

        node.installTap(onBus: bus, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
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
            // Forward raw buffer for ASR measurement — no second engine needed
            self.onRawBuffer?(buffer)
        }
    }

    private func computeSpectrum() -> [Float] {
        let n = fftSize
        let halfN = n / 2
        let log2n = vDSP_Length(log2(Float(n)))

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
                    // Use cached fftSetup — no allocation on this hot path
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
