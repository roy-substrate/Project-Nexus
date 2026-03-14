import Accelerate
import Foundation

enum DSPUtilities {
    static let fftSize = 1024
    static let halfFFTSize = 512

    // Bark scale critical band edges (Hz)
    static let barkBandEdges: [Float] = [
        20, 100, 200, 300, 400, 510, 630, 770, 920, 1080,
        1270, 1480, 1720, 2000, 2320, 2700, 3150, 3700, 4400, 5300,
        6400, 7700, 9500, 12000, 15500
    ]

    static func frequencyToBark(_ freq: Float) -> Float {
        13.0 * atan(0.00076 * freq) + 3.5 * atan(pow(freq / 7500.0, 2))
    }

    static func barkToFrequency(_ bark: Float) -> Float {
        // Approximation
        600.0 * sinh(bark / 6.0)
    }

    static func frequencyToBin(_ freq: Float, sampleRate: Float, fftSize: Int) -> Int {
        let bin = Int(freq * Float(fftSize) / sampleRate)
        return max(0, min(fftSize / 2 - 1, bin))
    }

    static func binToFrequency(_ bin: Int, sampleRate: Float, fftSize: Int) -> Float {
        Float(bin) * sampleRate / Float(fftSize)
    }

    static func generateWhiteNoise(count: Int) -> [Float] {
        (0..<count).map { _ in Float.random(in: -1...1) }
    }

    static func generateHannWindow(size: Int) -> [Float] {
        var window = [Float](repeating: 0, count: size)
        vDSP_hann_window(&window, vDSP_Length(size), Int32(vDSP_HANN_NORM))
        return window
    }

    static func bandpassFilter(
        _ signal: inout [Float],
        lowFreq: Float,
        highFreq: Float,
        sampleRate: Float
    ) {
        let n = signal.count
        let halfN = n / 2
        let log2n = vDSP_Length(log2(Float(n)))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Window the signal
        var window = generateHannWindow(size: n)
        vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(n))

        // Forward FFT
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        signal.withUnsafeMutableBufferPointer { signalPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                    signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfN))
                    }

                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                    // Zero out bins outside passband
                    let lowBin = frequencyToBin(lowFreq, sampleRate: sampleRate, fftSize: n)
                    let highBin = frequencyToBin(highFreq, sampleRate: sampleRate, fftSize: n)

                    for i in 0..<halfN {
                        if i < lowBin || i > highBin {
                            realPtr[i] = 0
                            imagPtr[i] = 0
                        }
                    }

                    // Inverse FFT
                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_INVERSE))

                    // Convert back to interleaved
                    var scale = 1.0 / Float(n)
                    signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ztoc(&split, 1, complexPtr, 2, vDSP_Length(halfN))
                    }
                    vDSP_vsmul(signalPtr.baseAddress!, 1, &scale, signalPtr.baseAddress!, 1, vDSP_Length(n))
                }
            }
        }
    }

    static func applySpectralNotch(
        _ signal: inout [Float],
        notchFrequencies: [Float],
        notchWidth: Float,
        sampleRate: Float
    ) {
        let n = signal.count
        let halfN = n / 2
        let log2n = vDSP_Length(log2(Float(n)))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        signal.withUnsafeMutableBufferPointer { signalPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                    signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfN))
                    }

                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                    // Apply notches
                    for notchFreq in notchFrequencies {
                        let centerBin = frequencyToBin(notchFreq, sampleRate: sampleRate, fftSize: n)
                        let widthBins = frequencyToBin(notchWidth, sampleRate: sampleRate, fftSize: n)

                        for i in max(0, centerBin - widthBins)...min(halfN - 1, centerBin + widthBins) {
                            let distance = abs(Float(i - centerBin)) / Float(widthBins)
                            let attenuation = min(1.0, distance)
                            realPtr[i] *= attenuation
                            imagPtr[i] *= attenuation
                        }
                    }

                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_INVERSE))

                    var scale = 1.0 / Float(n)
                    signalPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                        vDSP_ztoc(&split, 1, complexPtr, 2, vDSP_Length(halfN))
                    }
                    vDSP_vsmul(signalPtr.baseAddress!, 1, &scale, signalPtr.baseAddress!, 1, vDSP_Length(n))
                }
            }
        }
    }
}
