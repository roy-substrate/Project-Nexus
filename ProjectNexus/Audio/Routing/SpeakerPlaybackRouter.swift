import AVFoundation
import os

protocol AudioRouter {
    var mode: AudioMode { get }
    var isAvailable: Bool { get }
    func activate() throws
    func deactivate()
}

final class SpeakerPlaybackRouter: AudioRouter {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "SpeakerRouter")

    let mode = AudioMode.speakerPlayback
    let isAvailable = true

    func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.overrideOutputAudioPort(.speaker)
        logger.info("Speaker playback activated")
    }

    func deactivate() {
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(.none)
        logger.info("Speaker playback deactivated")
    }
}
