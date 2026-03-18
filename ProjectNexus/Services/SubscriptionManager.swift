import Foundation
import os

// MARK: - SubscriptionManager

/// All features are free — no paywall, no subscriptions.
/// isPro is always true so every feature is unlocked for all users.
@MainActor
@Observable
final class SubscriptionManager {

    /// Always true — all features are free.
    let isPro: Bool = true

    private let logger = Logger(subsystem: "com.nexus.store", category: "Subscriptions")

    init() {
        logger.info("All features unlocked (free)")
    }
}
