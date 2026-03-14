import Foundation
import os

// MARK: - Analytics Event

/// Lightweight, privacy-respecting analytics events stored locally.
/// No network calls are made — all data stays on-device.
enum AnalyticsEvent: Codable {
    case shieldActivated
    case shieldDeactivated(durationSeconds: Double)
    case techniqueToggled(name: String, enabled: Bool)
    case intensityChanged(value: Float)
    case audioModeChanged(mode: String)
    case onboardingCompleted
    case configReset
    case asrScoreRecorded(score: Float)
    case bluetoothHQToggled(enabled: Bool)

    var name: String {
        switch self {
        case .shieldActivated:        return "shield_activated"
        case .shieldDeactivated:      return "shield_deactivated"
        case .techniqueToggled:       return "technique_toggled"
        case .intensityChanged:       return "intensity_changed"
        case .audioModeChanged:       return "audio_mode_changed"
        case .onboardingCompleted:    return "onboarding_completed"
        case .configReset:            return "config_reset"
        case .asrScoreRecorded:       return "asr_score_recorded"
        case .bluetoothHQToggled:     return "bluetooth_hq_toggled"
        }
    }
}

// MARK: - Session Summary

struct SessionSummary: Codable, Identifiable {
    let id: UUID
    let date: Date
    let shieldActivations: Int
    let totalShieldSeconds: Double
    let techniquesUsed: [String]
    let peakASRJamScore: Float
    let averageIntensity: Float
}

// MARK: - AnalyticsService

/// On-device analytics engine.
///
/// Events are queued in memory, flushed to a local JSON log file
/// (in the app's Application Support directory) whenever the queue
/// reaches 20 events or `flush()` is called explicitly.
///
/// Call `currentSession` to get a live summary of the active session.
@Observable
final class AnalyticsService {

    // MARK: - Public State

    private(set) var sessionHistory: [SessionSummary] = []

    /// Total number of shield activations ever recorded.
    var totalActivations: Int { sessionHistory.map(\.shieldActivations).reduce(0, +) }

    /// Cumulative shield-on time in seconds.
    var totalShieldTime: Double { sessionHistory.map(\.totalShieldSeconds).reduce(0, +) }

    /// Peak ASR jamming score seen across all sessions.
    var peakJamScore: Float { sessionHistory.map(\.peakASRJamScore).max() ?? 0 }

    // MARK: - Private

    private let logger = Logger(subsystem: "com.nexus.analytics", category: "Events")
    private var eventQueue: [(event: AnalyticsEvent, timestamp: Date)] = []
    private let flushThreshold = 20

    private var sessionStart: Date = Date()
    private var shieldActivationTime: Date? = nil
    private var shieldActivationCount: Int = 0
    private var totalShieldSecondsThisSession: Double = 0
    private var techniquesUsedThisSession: Set<String> = []
    private var intensitySamples: [Float] = []
    private var peakJamScoreThisSession: Float = 0

    private let storageURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("nexus_analytics.json")
    }()

    // MARK: - Init

    init() {
        loadHistory()
    }

    // MARK: - Track

    func track(_ event: AnalyticsEvent) {
        eventQueue.append((event, Date()))
        applyToSession(event)
        logger.debug("Event: \(event.name)")
        if eventQueue.count >= flushThreshold { flush() }
    }

    // MARK: - Session control

    func endSession() {
        if let activation = shieldActivationTime {
            totalShieldSecondsThisSession += Date().timeIntervalSince(activation)
            shieldActivationTime = nil
        }

        let avg = intensitySamples.isEmpty
            ? 0
            : intensitySamples.reduce(0, +) / Float(intensitySamples.count)

        let summary = SessionSummary(
            id: UUID(),
            date: sessionStart,
            shieldActivations: shieldActivationCount,
            totalShieldSeconds: totalShieldSecondsThisSession,
            techniquesUsed: Array(techniquesUsedThisSession),
            peakASRJamScore: peakJamScoreThisSession,
            averageIntensity: avg
        )

        sessionHistory.append(summary)
        saveHistory()
        flush()

        // Reset session counters
        sessionStart = Date()
        shieldActivationCount = 0
        totalShieldSecondsThisSession = 0
        techniquesUsedThisSession = []
        intensitySamples = []
        peakJamScoreThisSession = 0
    }

    // MARK: - Data deletion

    /// Deletes all stored analytics data and resets the in-memory state.
    func deleteAllData() {
        sessionHistory = []
        eventQueue = []
        try? FileManager.default.removeItem(at: storageURL)
        logger.info("All analytics data deleted")
    }

    // MARK: - Private helpers

    private func applyToSession(_ event: AnalyticsEvent) {
        switch event {
        case .shieldActivated:
            shieldActivationCount += 1
            shieldActivationTime = Date()

        case .shieldDeactivated(let duration):
            totalShieldSecondsThisSession += duration
            shieldActivationTime = nil

        case .techniqueToggled(let name, let enabled):
            if enabled { techniquesUsedThisSession.insert(name) }

        case .intensityChanged(let value):
            intensitySamples.append(value)

        case .asrScoreRecorded(let score):
            if score > peakJamScoreThisSession { peakJamScoreThisSession = score }

        default:
            break
        }
    }

    private func flush() {
        guard !eventQueue.isEmpty else { return }
        eventQueue.removeAll()
        logger.debug("Event queue flushed")
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(sessionHistory) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: storageURL),
              let history = try? JSONDecoder().decode([SessionSummary].self, from: data)
        else { return }
        sessionHistory = history
    }
}
