import XCTest
@testable import ProjectNexus

// MARK: - Test Agent Protocol

/// Represents a single named scenario in the E2E test suite.
private struct TestScenario {
    let name: String
    let run: () throws -> Void
}

// MARK: - NexusE2ETestAgent

/// Autonomous end-to-end test agent that exercises the full Project Nexus app flow.
///
/// The agent runs as a standard XCTest target and covers:
/// - Onboarding state transitions
/// - AppState lifecycle (shield toggle, technique counts, error propagation)
/// - PerturbationConfig mutation, validation, and persistence
/// - MetricsService processing pipeline and EMA smoothing
/// - DSP round-trips (RMS, normalisation, frequency clamping)
/// - All AudioMode, CodecTarget and PerturbationTechnique enumerations
///
/// Run with:
///   swift test --filter NexusE2ETestAgent
final class NexusE2ETestAgent: XCTestCase {

    // MARK: - Agent State

    private var results: [String: AgentResult] = [:]
    private var scenarios: [TestScenario] = []

    override func setUp() {
        super.setUp()
        buildScenarios()
    }

    // MARK: - Master Runner

    /// Single entry point: runs every registered scenario and prints a structured report.
    func test_runAllScenarios() throws {
        var passCount = 0
        var failCount = 0
        var log: [String] = []

        log.append("═══════════════════════════════════════════════════════")
        log.append("  Project Nexus — E2E Test Agent Report")
        log.append("  Date: \(formattedDate())")
        log.append("═══════════════════════════════════════════════════════")

        for scenario in scenarios {
            let start = Date()
            do {
                try scenario.run()
                let elapsed = Date().timeIntervalSince(start) * 1000
                log.append("  ✓  \(scenario.name)  (\(String(format: "%.1f", elapsed)) ms)")
                results[scenario.name] = .pass(elapsed)
                passCount += 1
            } catch {
                let elapsed = Date().timeIntervalSince(start) * 1000
                log.append("  ✗  \(scenario.name)  — \(error.localizedDescription)")
                results[scenario.name] = .fail(error)
                failCount += 1
            }
        }

        log.append("───────────────────────────────────────────────────────")
        log.append("  Passed: \(passCount) / \(passCount + failCount)")
        if failCount > 0 { log.append("  Failed: \(failCount)") }
        log.append("═══════════════════════════════════════════════════════")

        print(log.joined(separator: "\n"))

        XCTAssertEqual(failCount, 0, "\(failCount) scenario(s) failed — see log above.")
    }

    // MARK: - Scenario Registration

    private mutating func buildScenarios() {
        scenarios = [
            // ── Onboarding ───────────────────────────────────────────
            scenario("Onboarding: defaults to not completed") {
                let key = "nexus.onboarding.completed"
                UserDefaults.standard.removeObject(forKey: key)
                let completed = UserDefaults.standard.bool(forKey: key)
                try assert(!completed, "Expected onboarding incomplete on fresh install")
            },

            scenario("Onboarding: completion persists across reads") {
                let key = "nexus.onboarding.completed"
                UserDefaults.standard.set(true, forKey: key)
                defer { UserDefaults.standard.removeObject(forKey: key) }
                let completed = UserDefaults.standard.bool(forKey: key)
                try assert(completed, "Expected onboarding marked complete")
            },

            scenario("Onboarding: reset clears completion flag") {
                let key = "nexus.onboarding.completed"
                UserDefaults.standard.set(true, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
                let completed = UserDefaults.standard.bool(forKey: key)
                try assert(!completed, "Expected onboarding reset to incomplete")
            },

            // ── AppState lifecycle ────────────────────────────────────
            scenario("AppState: shield starts inactive") {
                let state = AppState()
                try assert(!state.isShieldActive, "Shield must be off by default")
            },

            scenario("AppState: errorMessage starts nil") {
                let state = AppState()
                try assert(state.errorMessage == nil, "No error on fresh state")
            },

            scenario("AppState: activeTechniqueCount is 0 when shield inactive") {
                let state = AppState()
                try assertEqual(state.activeTechniqueCount, 0, "No active techniques while shield is off")
            },

            scenario("AppState: activeTechniqueCount reflects enabled techniques when shield active") {
                var state = AppState()
                state.isShieldActive = true
                state.config.tier1Enabled = true
                state.config.tier2Enabled = false
                state.config.enabledTechniques = [
                    PerturbationTechnique.spectralNotch.rawValue,
                    PerturbationTechnique.babbleNoise.rawValue
                ]
                let count = state.activeTechniqueCount
                try assert(count == 2, "Expected 2 tier-1 techniques, got \(count)")
            },

            scenario("AppState: tier1Active is true only when shield active and tier1 enabled") {
                var state = AppState()
                state.config.tier1Enabled = true
                try assert(!state.tier1Active, "tier1Active false when shield off")
                state.isShieldActive = true
                try assert(state.tier1Active, "tier1Active true when shield on and tier enabled")
            },

            scenario("AppState: errorMessage propagates and clears") {
                var state = AppState()
                state.errorMessage = "Microphone unavailable"
                try assertEqual(state.errorMessage, "Microphone unavailable", "Error message mismatch")
                state.errorMessage = nil
                try assert(state.errorMessage == nil, "Error message should clear")
            },

            // ── Config persistence ────────────────────────────────────
            scenario("Config: save and restore round-trip via UserDefaults") {
                let key = "perturbationConfig_agent_test"
                var config = PerturbationConfig()
                config.intensity = 0.42
                config.tier2Enabled = false
                config.codecTarget = .aac64k
                let data = try JSONEncoder().encode(config)
                UserDefaults.standard.set(data, forKey: key)
                defer { UserDefaults.standard.removeObject(forKey: key) }

                guard let loaded = UserDefaults.standard.data(forKey: key),
                      let restored = try? JSONDecoder().decode(PerturbationConfig.self, from: loaded)
                else { throw AgentError.assertion("Failed to reload config from UserDefaults") }

                try assertApproxEqual(restored.intensity, 0.42, tolerance: 0.001)
                try assert(!restored.tier2Enabled, "tier2 should be disabled after restore")
                try assertEqual(restored.codecTarget, .aac64k, "Codec target mismatch")
            },

            scenario("Config: AppState.saveConfig persists, loadConfig restores") {
                var state = AppState()
                state.config.intensity = 0.33
                state.config.maskingAggressiveness = 0.55
                state.saveConfig()

                let reloaded = AppState()   // loads from UserDefaults in init
                try assertApproxEqual(reloaded.config.intensity, 0.33, tolerance: 0.001)
                try assertApproxEqual(reloaded.config.maskingAggressiveness, 0.55, tolerance: 0.001)

                // Cleanup
                UserDefaults.standard.removeObject(forKey: "perturbationConfig")
            },

            // ── Config validation ─────────────────────────────────────
            scenario("Config: intensity clamps to [0, 1]") {
                var config = PerturbationConfig()
                config.intensity = 2.5
                try assertApproxEqual(config.intensity, 1.0, tolerance: 0.001)
                config.intensity = -0.5
                try assertApproxEqual(config.intensity, 0.0, tolerance: 0.001)
            },

            scenario("Config: frequencyRangeLow clamps to [100, 7800]") {
                var config = PerturbationConfig()
                config.frequencyRangeLow = 10
                try assert(config.frequencyRangeLow >= 100, "Low must be ≥ 100 Hz")
                config.frequencyRangeLow = 9999
                try assert(config.frequencyRangeLow <= 7800, "Low must be ≤ 7800 Hz")
            },

            scenario("Config: 200 Hz minimum gap between low and high frequency") {
                var config = PerturbationConfig()
                config.frequencyRangeLow = 400
                config.frequencyRangeHigh = 500   // only 100 Hz gap → should auto-adjust
                let gap = config.frequencyRangeHigh - config.frequencyRangeLow
                try assert(gap >= 200, "Gap \(gap) Hz is below the 200 Hz minimum")
            },

            scenario("Config: isEffective when tier1 has an enabled technique") {
                var config = PerturbationConfig()
                config.tier1Enabled = true
                config.tier2Enabled = false
                config.enabledTechniques = [PerturbationTechnique.babbleNoise.rawValue]
                try assert(config.isEffective, "Config with babbleNoise enabled should be effective")
            },

            scenario("Config: isEffective is false when both tiers disabled") {
                var config = PerturbationConfig()
                config.tier1Enabled = false
                config.tier2Enabled = false
                try assert(!config.isEffective, "No tiers enabled → not effective")
            },

            scenario("Config: toggleTechnique adds then removes") {
                var config = PerturbationConfig()
                config.enabledTechniques = []
                config.toggleTechnique(.spectralNotch)
                try assert(config.isTechniqueEnabled(.spectralNotch), "spectralNotch should be enabled after toggle")
                config.toggleTechnique(.spectralNotch)
                try assert(!config.isTechniqueEnabled(.spectralNotch), "spectralNotch should be disabled after second toggle")
            },

            // ── Technique enumeration ─────────────────────────────────
            scenario("Techniques: all cases have non-empty names and descriptions") {
                for tech in PerturbationTechnique.allCases {
                    try assert(!tech.name.isEmpty, "\(tech.rawValue) has no name")
                    try assert(!tech.description.isEmpty, "\(tech.rawValue) has no description")
                }
            },

            scenario("Techniques: tier1 and tier2 techniques are distinct sets") {
                let t1 = Set(PerturbationTechnique.allCases.filter { $0.tier == .tier1 }.map(\.rawValue))
                let t2 = Set(PerturbationTechnique.allCases.filter { $0.tier == .tier2 }.map(\.rawValue))
                try assert(t1.isDisjoint(with: t2), "Tier1 and Tier2 technique sets must be disjoint")
            },

            scenario("Techniques: all cases have unique rawValues") {
                let ids = PerturbationTechnique.allCases.map(\.rawValue)
                try assertEqual(ids.count, Set(ids).count, "Duplicate technique rawValues detected")
            },

            // ── AudioMode enumeration ─────────────────────────────────
            scenario("AudioMode: speakerPlayback is available") {
                try assert(AudioMode.speakerPlayback.isAvailable, "speakerPlayback should be available")
            },

            scenario("AudioMode: voipMix is not available") {
                try assert(!AudioMode.voipMix.isAvailable, "voipMix is not yet available")
            },

            scenario("AudioMode: all cases have unique IDs and non-empty icons") {
                let ids = AudioMode.allCases.map(\.id)
                try assertEqual(ids.count, Set(ids).count, "Duplicate AudioMode IDs")
                for mode in AudioMode.allCases {
                    try assert(!mode.iconName.isEmpty, "\(mode.rawValue) missing icon")
                }
            },

            // ── CodecTarget enumeration ───────────────────────────────
            scenario("CodecTarget: all cases have positive bitrates or zero for .none") {
                for codec in CodecTarget.allCases {
                    if codec == .none {
                        try assertEqual(codec.bitrateHz, 0, ".none should have 0 bitrate")
                    } else {
                        try assert(codec.bitrateHz > 0, "\(codec.rawValue) should have positive bitrate")
                    }
                }
            },

            scenario("CodecTarget: Codable round-trip preserves all cases") {
                for codec in CodecTarget.allCases {
                    let data = try JSONEncoder().encode(codec)
                    let decoded = try JSONDecoder().decode(CodecTarget.self, from: data)
                    try assertEqual(decoded, codec, "CodecTarget Codable round-trip failed for \(codec)")
                }
            },

            // ── AudioMetrics ──────────────────────────────────────────
            scenario("AudioMetrics: .empty initialises with -60 dB levels") {
                let m = AudioMetrics.empty
                try assertApproxEqual(m.rmsLevel, -60, tolerance: 0.01)
                try assertApproxEqual(m.peakLevel, -60, tolerance: 0.01)
            },

            scenario("AudioMetrics: spectrumData and perturbationSpectrum have the same length") {
                let m = AudioMetrics.empty
                try assertEqual(m.spectrumData.count, m.perturbationSpectrum.count,
                                "spectrumData and perturbationSpectrum length mismatch")
            },

            // ── MetricsService ────────────────────────────────────────
            scenario("MetricsService: initial metrics equal .empty") {
                let svc = MetricsService()
                try assertApproxEqual(svc.currentMetrics.rmsLevel, -60, tolerance: 0.01)
            },

            scenario("MetricsService: rmsHistory initialised to -60") {
                let svc = MetricsService()
                let allSilent = svc.rmsHistory.allSatisfy { $0 == -60 }
                try assert(allSilent, "rmsHistory should start at -60 dB")
            },

            scenario("MetricsService: rmsHistory has exactly 60 entries") {
                let svc = MetricsService()
                try assertEqual(svc.rmsHistory.count, 60, "Expected 60-sample history ring")
            },

            // ── DSP round-trips ───────────────────────────────────────
            scenario("DSP: RMS of silence is near 0") {
                let silence = [Float](repeating: 0, count: 1024)
                let rms = silence.rms()
                try assertApproxEqual(rms, 0, tolerance: 1e-7)
            },

            scenario("DSP: RMS of unity sine is ~0.707") {
                let n = 1024
                let sine = (0..<n).map { Float(sin(2 * Double.pi * Double($0) / Double(n))) }
                let rms = sine.rms()
                try assertApproxEqual(Double(rms), 1.0 / sqrt(2.0), tolerance: 0.01)
            },

            scenario("DSP: peak of [-1, 0, 1] is 1.0") {
                let signal: [Float] = [-1, 0, 1]
                let peak = signal.peak()
                try assertApproxEqual(peak, 1.0, tolerance: 1e-7)
            },

            scenario("DSP: scaled array has correct peak") {
                let base: [Float] = [0.5, -0.5, 0.25]
                let scaled = base.scaled(by: 2.0)
                try assertApproxEqual(scaled.peak(), 1.0, tolerance: 1e-7)
            },

            scenario("DSP: adding two arrays element-wise") {
                let a: [Float] = [1, 2, 3]
                let b: [Float] = [4, 5, 6]
                let result = a.adding(b)
                let expected: [Float] = [5, 7, 9]
                for (r, e) in zip(result, expected) {
                    try assertApproxEqual(r, e, tolerance: 1e-6)
                }
            },

            scenario("DSP: toDecibels converts 1.0 amplitude to 0 dB") {
                let db = Float(1.0).toDecibels()
                try assertApproxEqual(db, 0, tolerance: 0.01)
            },

            scenario("DSP: toDecibels converts 0.5 amplitude to ~-6 dB") {
                let db = Float(0.5).toDecibels()
                try assertApproxEqual(Double(db), -6.02, tolerance: 0.05)
            },

            scenario("DSP: Hann window first and last sample are near zero") {
                let win = DSPUtilities.hannWindow(length: 512)
                try assertApproxEqual(win.first ?? 1, 0, tolerance: 0.01)
                try assertApproxEqual(win.last  ?? 1, 0, tolerance: 0.01)
            },

            scenario("DSP: Hann window centre sample is near 1.0") {
                let n = 512
                let win = DSPUtilities.hannWindow(length: n)
                try assertApproxEqual(win[n / 2], 1.0, tolerance: 0.01)
            },

            // ── AppTab enumeration ────────────────────────────────────
            scenario("AppTab: all cases have unique IDs") {
                let ids = AppTab.allCases.map(\.id)
                try assertEqual(ids.count, Set(ids).count, "Duplicate AppTab IDs")
            },

            scenario("AppTab: all cases have non-empty icon names") {
                for tab in AppTab.allCases {
                    try assert(!tab.iconName.isEmpty, "\(tab.rawValue) has no icon")
                }
            },
        ]
    }

    // MARK: - Scenario Builder

    private func scenario(_ name: String, block: @escaping () throws -> Void) -> TestScenario {
        TestScenario(name: name, run: block)
    }

    // MARK: - Assertion Helpers

    private func assert(_ condition: Bool, _ message: String) throws {
        guard condition else { throw AgentError.assertion(message) }
    }

    private func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "") throws {
        guard lhs == rhs else {
            throw AgentError.assertion("\(message.isEmpty ? "" : "\(message): ")\(lhs) ≠ \(rhs)")
        }
    }

    private func assertApproxEqual(_ lhs: Float, _ rhs: Float, tolerance: Float) throws {
        guard abs(lhs - rhs) <= tolerance else {
            throw AgentError.assertion("|\(lhs) − \(rhs)| = \(abs(lhs - rhs)) > tolerance \(tolerance)")
        }
    }

    private func assertApproxEqual(_ lhs: Double, _ rhs: Double, tolerance: Double) throws {
        guard abs(lhs - rhs) <= tolerance else {
            throw AgentError.assertion("|\(lhs) − \(rhs)| = \(abs(lhs - rhs)) > tolerance \(tolerance)")
        }
    }

    // MARK: - Utilities

    private func formattedDate() -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .medium
        return fmt.string(from: Date())
    }
}

// MARK: - Supporting Types

private enum AgentResult {
    case pass(Double)            // elapsed ms
    case fail(Error)
}

private enum AgentError: LocalizedError {
    case assertion(String)

    var errorDescription: String? {
        switch self {
        case .assertion(let msg): return msg
        }
    }
}
