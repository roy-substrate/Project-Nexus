import Foundation
import Accelerate
import os

enum UAPVariant: String, CaseIterable, Identifiable, Codable {
    case whisperOptimized = "Whisper"
    case deepspeechOptimized = "DeepSpeech"
    case ensemble = "Ensemble"

    var id: String { rawValue }

    var filename: String {
        switch self {
        case .whisperOptimized: "whisper_uap_v1"
        case .deepspeechOptimized: "deepspeech_uap_v1"
        case .ensemble: "ensemble_uap_v1"
        }
    }
}

final class UAPManager {
    private let logger = Logger(subsystem: "com.nexus.ml", category: "UAP")

    private var uapBuffers: [UAPVariant: [Float]] = [:]
    private var readPositions: [UAPVariant: Int] = [:]
    private let crossfadeSamples = 2400  // 50ms at 48kHz

    private(set) var currentVariant: UAPVariant = .ensemble
    private(set) var isLoaded = false

    func loadUAPs() {
        for variant in UAPVariant.allCases {
            if let buffer = loadUAPFromBundle(variant) {
                uapBuffers[variant] = buffer
                readPositions[variant] = 0
                logger.info("Loaded UAP: \(variant.rawValue) (\(buffer.count) samples)")
            } else {
                // Generate placeholder UAP if bundle resource not found
                let placeholder = generatePlaceholderUAP(variant: variant)
                uapBuffers[variant] = placeholder
                readPositions[variant] = 0
                logger.info("Generated placeholder UAP for \(variant.rawValue)")
            }
        }
        isLoaded = true
    }

    func selectVariant(_ variant: UAPVariant) {
        currentVariant = variant
    }

    func fillBuffer(_ buffer: UnsafeMutablePointer<Float>, frameCount: Int, gain: Float = 1.0) {
        guard let uap = uapBuffers[currentVariant],
              !uap.isEmpty else {
            memset(buffer, 0, frameCount * MemoryLayout<Float>.size)
            return
        }

        var pos = readPositions[currentVariant] ?? 0
        let uapLength = uap.count
        var written = 0

        uap.withUnsafeBufferPointer { uapPtr in
            guard let uapBase = uapPtr.baseAddress else { return }

            // Bulk vectorized copy for the non-crossfade region (the common case).
            // Only fall through to the scalar crossfade loop when near the loop boundary.
            while written < frameCount {
                let distanceToEnd = uapLength - pos
                let remaining = frameCount - written

                if distanceToEnd >= crossfadeSamples {
                    // Safe bulk region: copy min(remaining, distanceToEnd - crossfadeSamples) samples
                    let bulkCount = min(remaining, distanceToEnd - crossfadeSamples)
                    if bulkCount > 0 {
                        var g = gain
                        vDSP_vsmul(uapBase + pos, 1, &g, buffer + written, 1, vDSP_Length(bulkCount))
                        pos += bulkCount
                        written += bulkCount
                        continue
                    }
                }

                // Scalar crossfade path — only active within crossfadeSamples of the loop boundary.
                let fadeOut = Float(distanceToEnd) / Float(crossfadeSamples)
                let fadeIn = 1.0 - fadeOut
                let wrapPos = crossfadeSamples - distanceToEnd
                let sample: Float
                if wrapPos < uapLength {
                    sample = uap[pos] * fadeOut + uap[wrapPos] * fadeIn
                } else {
                    sample = uap[pos] * fadeOut
                }
                buffer[written] = sample * gain
                pos = (pos + 1) % uapLength
                written += 1
            }
        }

        readPositions[currentVariant] = pos
    }

    private func loadUAPFromBundle(_ variant: UAPVariant) -> [Float]? {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif

        guard let url = bundle.url(forResource: variant.filename, withExtension: "bin") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let count = data.count / MemoryLayout<Float>.size
            var buffer = [Float](repeating: 0, count: count)
            _ = buffer.withUnsafeMutableBytes { ptr in
                data.copyBytes(to: ptr)
            }
            return buffer
        } catch {
            logger.error("Failed to load UAP \(variant.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    private func generatePlaceholderUAP(variant: UAPVariant) -> [Float] {
        // Generate a scientifically-motivated placeholder UAP
        // Uses frequency-band noise shaped to target ASR mel-spectrogram features
        let sampleRate: Float = 48000
        let duration: Float = 1.0
        let count = Int(sampleRate * duration)
        var uap = [Float](repeating: 0, count: count)

        // Seed varies by variant for different perturbation characteristics
        let seed: Float
        switch variant {
        case .whisperOptimized:
            // Target Whisper's 80-channel mel filterbank (focus 200Hz-3.5kHz)
            seed = 1.0
        case .deepspeechOptimized:
            // Target DeepSpeech's MFCC features (focus 300Hz-4kHz)
            seed = 2.0
        case .ensemble:
            // Broadband coverage across all ASR feature extraction ranges
            seed = 3.0
        }

        // Generate multi-frequency perturbation
        let frequencies: [Float] = [
            350, 500, 700, 1000, 1400, 2000, 2800, 3500
        ]

        for freq in frequencies {
            let amplitude: Float = 0.01 * (1.0 + seed * 0.1)
            let phaseOffset = Float.random(in: 0...(2 * .pi))

            for i in 0..<count {
                let t = Float(i) / sampleRate
                uap[i] += amplitude * sinf(2 * .pi * freq * t + phaseOffset)
            }
        }

        // Add broadband noise component
        for i in 0..<count {
            uap[i] += Float.random(in: -0.005...0.005)
        }

        // Bandpass to 300-4000Hz
        DSPUtilities.bandpassFilter(&uap, lowFreq: 300, highFreq: 4000, sampleRate: sampleRate)

        // Normalize to epsilon = 0.01
        var peak: Float = 0
        vDSP_maxmgv(uap, 1, &peak, vDSP_Length(count))
        if peak > 0 {
            var scale: Float = 0.01 / peak
            vDSP_vsmul(uap, 1, &scale, &uap, 1, vDSP_Length(count))
        }

        return uap
    }
}
