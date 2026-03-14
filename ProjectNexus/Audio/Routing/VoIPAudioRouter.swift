import Foundation
import os

enum VoIPError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "VoIP audio mixing is not yet available on iOS. Use Speaker Playback mode instead."
        }
    }
}

final class VoIPAudioRouter: AudioRouter {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "VoIPRouter")

    let mode = AudioMode.voipMix
    let isAvailable = false

    func activate() throws {
        logger.warning("VoIP mode requested but not yet implemented")
        throw VoIPError.notAvailable
    }

    func deactivate() {
        // No-op
    }
}
