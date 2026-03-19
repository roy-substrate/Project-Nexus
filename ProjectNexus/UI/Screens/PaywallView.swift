import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptionManager: SubscriptionManager

    @State private var errorMessage: String? = nil
    @State private var appeared = false

    var body: some View {
        ZStack {
            PixelColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button("[ × ]") { dismiss() }
                        .font(PixelFont.terminal(14))
                        .foregroundStyle(PixelColor.textSecondary)
                        .padding(20)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 0) {
                            Text("> ")
                                .foregroundStyle(PixelColor.phosphor)
                                .phosphorGlow()
                            Text("UPGRADE TO PRO")
                                .foregroundStyle(PixelColor.text)
                        }
                        .font(PixelFont.hero(28))

                        Text("UNLOCK THE AI ADVERSARIAL LAYER")
                            .font(PixelFont.terminal(13))
                            .foregroundStyle(PixelColor.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(PixelAnimation.appear.delay(0.05), value: appeared)

                    // Feature comparison
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("T1: ACOUSTIC MASKING", included: true, isPro: false)
                        featureRow("T1: SPECTRAL NOTCH", included: true, isPro: false)
                        featureRow("T1: FREQUENCY SWEEP", included: true, isPro: false)
                        featureRow("T2: ADVERSARIAL AI (UAP)", included: true, isPro: true)
                        featureRow("T2: UAP VARIANT SELECTION", included: true, isPro: true)
                        featureRow("DIAGNOSTICS: FULL ACCESS", included: true, isPro: true)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)
                    .animation(PixelAnimation.appear.delay(0.15), value: appeared)

                    // Price
                    VStack(alignment: .leading, spacing: 6) {
                        Text("$9.99")
                            .font(PixelFont.hero(36))
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        Text("ONE-TIME PURCHASE · NO SUBSCRIPTION")
                            .font(PixelFont.terminal(11))
                            .foregroundStyle(PixelColor.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(PixelAnimation.appear.delay(0.25), value: appeared)
                }
                .padding(.horizontal, 34)

                Spacer()

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(PixelFont.terminal(11))
                        .foregroundStyle(PixelColor.warning)
                        .padding(.horizontal, 34)
                        .padding(.bottom, 8)
                }

                // CTA
                VStack(spacing: 12) {
                    Button {
                        Task {
                            errorMessage = nil
                            do {
                                try await subscriptionManager.purchase()
                                if subscriptionManager.isPro { dismiss() }
                            } catch {
                                errorMessage = "PURCHASE FAILED: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        if subscriptionManager.isLoading {
                            Text("[ PROCESSING... ]")
                        } else {
                            Text("[ UNLOCK PRO — $9.99 ]")
                        }
                    }
                    .buttonStyle(PixelButtonStyle(active: true))
                    .disabled(subscriptionManager.isLoading)

                    Button("[ RESTORE PURCHASE ]") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                    .font(PixelFont.terminal(12))
                    .foregroundStyle(PixelColor.textSecondary)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 54)
                .opacity(appeared ? 1 : 0)
                .animation(PixelAnimation.appear.delay(0.3), value: appeared)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }

    private func featureRow(_ title: String, included: Bool, isPro: Bool) -> some View {
        HStack(spacing: 8) {
            Text(included ? "✓" : "×")
                .font(PixelFont.terminal(12, weight: .bold))
                .foregroundStyle(isPro ? PixelColor.phosphor : PixelColor.textSecondary)
                .if(isPro) { $0.phosphorGlow() }
                .frame(width: 14)
            Text(title)
                .font(PixelFont.terminal(12))
                .foregroundStyle(isPro ? PixelColor.text : PixelColor.textSecondary)
            if isPro {
                Spacer()
                Text("PRO")
                    .font(PixelFont.terminal(10, weight: .bold))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
            }
        }
    }
}
