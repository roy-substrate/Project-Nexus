import Foundation
import Accelerate

final class CodecSimulator {
    let codecTarget: CodecTarget

    private var codecEnvelope: [Float]
    private let fftSize: Int
    private let sampleRate: Float
    // Reused across every applyCodecToBlock call — creating/destroying FFTSetup
    // is expensive and was previously happening once per OLA block.
    private let fftSetup: FFTSetup
    private let hannWindow: [Float]

    enum CodecSimulatorError: LocalizedError {
        case fftSetupFailed(fftSize: Int)
        var errorDescription: String? {
            switch self {
            case .fftSetupFailed(let size):
                return "CodecSimulator: vDSP_create_fftsetup failed for fftSize=\(size). fftSize must be a power of 2."
            }
        }
    }

    init(codecTarget: CodecTarget = .opus64k, fftSize: Int = 1024, sampleRate: Float = 48000) throws {
        self.codecTarget = codecTarget
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        self.codecEnvelope = [Float](repeating: 1, count: fftSize / 2)
        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            throw CodecSimulatorError.fftSetupFailed(fftSize: fftSize)
        }
        self.fftSetup = setup
        self.hannWindow = DSPUtilities.generateHannWindow(size: fftSize)
        computeEnvelope()
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func applyToSpectrum(_ spectrum: inout [Float]) {
        guard codecTarget != .none else { return }
        let count = min(spectrum.count, codecEnvelope.count)
        vDSP_vmul(spectrum, 1, codecEnvelope, 1, &spectrum, 1, vDSP_Length(count))
    }

    func applyToSignal(_ signal: inout [Float]) {
        guard codecTarget != .none else { return }
        let n = signal.count
        guard n >= fftSize else { return }

        // Process in overlapping blocks
        let hopSize = fftSize / 2
        var outputAccumulator = [Float](repeating: 0, count: n + fftSize)
        var block = [Float](repeating: 0, count: fftSize)
        var position = 0

        while position + fftSize <= n {
            // Extract block
            for i in 0..<fftSize {
                block[i] = signal[position + i]
            }

            // Apply codec envelope in frequency domain
            applyCodecToBlock(&block)

            // Overlap-add
            for i in 0..<fftSize {
                outputAccumulator[position + i] += block[i]
            }

            position += hopSize
        }

        // Copy back
        for i in 0..<n {
            signal[i] = outputAccumulator[i]
        }
    }

    private func applyCodecToBlock(_ block: inout [Float]) {
        let halfN = fftSize / 2
        let log2n = vDSP_Length(log2(Float(fftSize)))

        vDSP_vmul(block, 1, hannWindow, 1, &block, 1, vDSP_Length(fftSize))

        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        block.withUnsafeMutableBufferPointer { blockPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                    blockPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfN))
                    }

                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                    // Apply codec envelope
                    vDSP_vmul(realPtr.baseAddress!, 1, self.codecEnvelope, 1, realPtr.baseAddress!, 1, vDSP_Length(halfN))
                    vDSP_vmul(imagPtr.baseAddress!, 1, self.codecEnvelope, 1, imagPtr.baseAddress!, 1, vDSP_Length(halfN))

                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_INVERSE))

                    var scale = 1.0 / Float(fftSize)
                    blockPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ztoc(&split, 1, complexPtr, 2, vDSP_Length(halfN))
                    }
                    vDSP_vsmul(blockPtr.baseAddress!, 1, &scale, blockPtr.baseAddress!, 1, vDSP_Length(fftSize))
                }
            }
        }
    }

    private func computeEnvelope() {
        let halfN = fftSize / 2

        for bin in 0..<halfN {
            let freq = DSPUtilities.binToFrequency(bin, sampleRate: sampleRate, fftSize: fftSize)

            switch codecTarget {
            case .opus32k:
                // Opus at 32kbps: effective bandwidth ~8kHz, aggressive below 200Hz and above 6kHz
                if freq < 100 {
                    codecEnvelope[bin] = 0.1
                } else if freq < 300 {
                    codecEnvelope[bin] = 0.4 + 0.6 * (freq - 100) / 200
                } else if freq <= 4000 {
                    codecEnvelope[bin] = 1.0
                } else if freq <= 8000 {
                    codecEnvelope[bin] = 1.0 - 0.7 * (freq - 4000) / 4000
                } else {
                    codecEnvelope[bin] = 0.05
                }
            case .opus64k:
                // Better preservation across range
                if freq < 50 {
                    codecEnvelope[bin] = 0.2
                } else if freq < 200 {
                    codecEnvelope[bin] = 0.5 + 0.5 * (freq - 50) / 150
                } else if freq <= 6000 {
                    codecEnvelope[bin] = 1.0
                } else if freq <= 12000 {
                    codecEnvelope[bin] = 1.0 - 0.5 * (freq - 6000) / 6000
                } else {
                    codecEnvelope[bin] = 0.15
                }
            case .opus128k:
                // Near-transparent
                if freq < 30 {
                    codecEnvelope[bin] = 0.3
                } else if freq <= 16000 {
                    codecEnvelope[bin] = 1.0
                } else {
                    codecEnvelope[bin] = 0.5
                }
            case .aac64k:
                // AAC at 64kbps: good mid-range, weaker extremes
                if freq < 100 {
                    codecEnvelope[bin] = 0.15
                } else if freq < 300 {
                    codecEnvelope[bin] = 0.4 + 0.6 * (freq - 100) / 200
                } else if freq <= 5000 {
                    codecEnvelope[bin] = 1.0
                } else if freq <= 10000 {
                    codecEnvelope[bin] = 1.0 - 0.6 * (freq - 5000) / 5000
                } else {
                    codecEnvelope[bin] = 0.1
                }
            case .none:
                codecEnvelope[bin] = 1.0
            }
        }
    }
}
