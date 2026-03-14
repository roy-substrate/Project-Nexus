import XCTest
@testable import ProjectNexus

/// Tests for onboarding state and first-launch experience.
final class OnboardingTests: XCTestCase {

    private let onboardingKey = "nexus.onboarding.completed"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        super.tearDown()
    }

    // MARK: - First launch state

    func test_onboarding_defaultsToNotCompleted() {
        let completed = UserDefaults.standard.bool(forKey: onboardingKey)
        XCTAssertFalse(completed, "Onboarding should not be marked complete on a fresh install")
    }

    func test_onboarding_completionPersists() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        let completed = UserDefaults.standard.bool(forKey: onboardingKey)
        XCTAssertTrue(completed)
    }

    func test_onboarding_canBeReset() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        let completed = UserDefaults.standard.bool(forKey: onboardingKey)
        XCTAssertFalse(completed, "Removing the key should reset onboarding state")
    }

    // MARK: - AppState error state (used after onboarding for shield alerts)

    func test_appState_errorMessage_defaultsToNil() {
        let state = AppState()
        XCTAssertNil(state.errorMessage)
    }

    func test_appState_errorMessage_canBeSet() {
        var state = AppState()
        state.errorMessage = "Microphone permission denied"
        XCTAssertEqual(state.errorMessage, "Microphone permission denied")
    }

    func test_appState_errorMessage_canBeCleared() {
        var state = AppState()
        state.errorMessage = "Some error"
        state.errorMessage = nil
        XCTAssertNil(state.errorMessage)
    }

    // MARK: - AudioMode for routing screen

    func test_audioMode_speakerPlayback_isAvailable() {
        XCTAssertTrue(AudioMode.speakerPlayback.isAvailable)
    }

    func test_audioMode_voipMix_isNotAvailable() {
        XCTAssertFalse(AudioMode.voipMix.isAvailable)
    }

    func test_audioMode_allCases_haveUniqueIds() {
        let ids = AudioMode.allCases.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_audioMode_allCases_haveNonEmptyIconNames() {
        for mode in AudioMode.allCases {
            XCTAssertFalse(mode.iconName.isEmpty, "\(mode.rawValue) should have an icon")
        }
    }

    func test_audioMode_allCases_haveNonEmptyStatusText() {
        for mode in AudioMode.allCases {
            XCTAssertFalse(mode.statusText.isEmpty, "\(mode.rawValue) should have status text")
        }
    }
}
