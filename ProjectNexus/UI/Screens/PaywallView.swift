import SwiftUI

// All features are now free — PaywallView is unused.
// Kept as a minimal stub to avoid breaking any residual references.

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptionManager: SubscriptionManager

    var body: some View {
        // All features are free — dismiss immediately if shown.
        Color.clear
            .onAppear { dismiss() }
    }
}
