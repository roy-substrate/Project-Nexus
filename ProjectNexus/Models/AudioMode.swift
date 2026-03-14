import Foundation

enum AudioMode: String, CaseIterable, Identifiable, Codable {
    case speakerPlayback = "Speaker Playback"
    case voipMix = "VoIP Mix"

    var id: String { rawValue }

    var isAvailable: Bool {
        switch self {
        case .speakerPlayback: true
        case .voipMix: false
        }
    }

    var iconName: String {
        switch self {
        case .speakerPlayback: "speaker.wave.3.fill"
        case .voipMix: "phone.arrow.up.right.fill"
        }
    }

    var statusText: String {
        switch self {
        case .speakerPlayback: "Active"
        case .voipMix: "Coming Soon"
        }
    }
}
