import AVFoundation
import os

final class AudioSessionConfigurator {
    static let shared = AudioSessionConfigurator()

    private let logger = Logger(subsystem: "com.nexus.audio", category: "Session")
    private let session = AVAudioSession.sharedInstance()

    var sampleRate: Double { session.sampleRate }
    var ioBufferDuration: TimeInterval { session.ioBufferDuration }

    private init() {
        setupNotifications()
    }

    func configure() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth]
        )
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.005)
        logger.info("Session configured: \(self.session.sampleRate)Hz, buffer \(self.session.ioBufferDuration * 1000, format: .fixed(precision: 1))ms")
    }

    func activate() throws {
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        logger.info("Session activated")
    }

    func deactivate() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            logger.info("Session deactivated")
        } catch {
            logger.warning("Failed to deactivate session: \(error.localizedDescription)")
        }
    }

    var currentRoute: String {
        session.currentRoute.outputs.map { $0.portName }.joined(separator: ", ")
    }

    var isMicrophoneAvailable: Bool {
        session.isInputAvailable
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            logger.info("Audio session interrupted")
            NotificationCenter.default.post(name: .audioSessionInterrupted, object: nil)
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                logger.info("Audio session interruption ended, should resume")
                NotificationCenter.default.post(name: .audioSessionResumed, object: nil)
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        logger.info("Audio route changed: \(String(describing: reason)), output: \(self.currentRoute)")
        NotificationCenter.default.post(name: .audioRouteChanged, object: nil)
    }
}

extension Notification.Name {
    static let audioSessionInterrupted = Notification.Name("audioSessionInterrupted")
    static let audioSessionResumed = Notification.Name("audioSessionResumed")
    static let audioRouteChanged = Notification.Name("audioRouteChanged")
}
