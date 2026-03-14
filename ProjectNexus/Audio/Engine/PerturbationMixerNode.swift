import AVFoundation
import os

final class PerturbationMixerNode {
    private let logger = Logger(subsystem: "com.nexus.audio", category: "PertMixer")

    let mixerNode = AVAudioMixerNode()
    private(set) var gain: Float = 1.0

    func setGain(_ newGain: Float) {
        gain = max(0, min(1, newGain))
        mixerNode.outputVolume = gain
        logger.debug("Perturbation gain set to \(self.gain)")
    }

    func mute() {
        mixerNode.outputVolume = 0
    }

    func unmute() {
        mixerNode.outputVolume = gain
    }
}
