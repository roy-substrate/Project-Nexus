import SwiftUI
import StoreKit

// MARK: - PaywallView
//
// CEO pricing decision:
//   Monthly:  $3.99/month  (7-day free trial)
//   Annual:   $19.99/year  (~$1.67/month — save 58%)
//
// Free tier:  Tier 1 acoustic shield
// Pro tier:   Tier 2 UAP adversarial + Session History + Diagnostics

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptionManager: SubscriptionManager

    @State private var selectedProduct: String = NexusProduct.annual.rawValue

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    featuresSection
                    productsSection
                    ctaSection
                    footerSection
                }
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not now") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Purchase Error", isPresented: Binding(
                get: { subscriptionManager.purchaseError != nil },
                set: { if !$0 { subscriptionManager.purchaseError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.purchaseError ?? "")
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Glow + icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 8)

                    Image(systemName: "shield.checkered.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 28)

            VStack(spacing: 10) {
                Text("Nexus Shield Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Full AI voice protection.\nUnlock every weapon.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "waveform",
                iconColor: NexusTheme.tier1,
                title: "Acoustic Layer",
                detail: "Psychoacoustic masking · 300–4kHz",
                badge: "FREE"
            )
            Divider().padding(.leading, 60).opacity(0.3)
            featureRow(
                icon: "brain",
                iconColor: NexusTheme.tier2,
                title: "Adversarial AI (Tier 2)",
                detail: "Universal perturbations · Whisper, DeepSpeech",
                badge: "PRO"
            )
            Divider().padding(.leading, 60).opacity(0.3)
            featureRow(
                icon: "chart.bar.xaxis",
                iconColor: .orange,
                title: "Full Diagnostics",
                detail: "Live spectrum, ASR jam score, CPU metrics",
                badge: "PRO"
            )
            Divider().padding(.leading, 60).opacity(0.3)
            featureRow(
                icon: "clock.arrow.circlepath",
                iconColor: .green,
                title: "Session History",
                detail: "All your protection sessions logged locally",
                badge: "PRO"
            )
            Divider().padding(.leading, 60).opacity(0.3)
            featureRow(
                icon: "slider.horizontal.3",
                iconColor: .blue,
                title: "Advanced Settings",
                detail: "Custom frequency range, codec targeting",
                badge: "PRO"
            )
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private func featureRow(icon: String, iconColor: Color, title: String, detail: String, badge: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(iconColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Spacer()

            Text(badge)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(badge == "FREE" ? Color.white.opacity(0.4) : NexusTheme.tier2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(badge == "FREE" ? Color.white.opacity(0.06) : NexusTheme.tier2.opacity(0.15)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 10) {
            if subscriptionManager.products.isEmpty {
                // Loading state
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 76)
                        .redacted(reason: .placeholder)
                }
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct == product.id
        let isAnnual = product.id == NexusProduct.annual.rawValue

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                selectedProduct = product.id
            }
        } label: {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(isAnnual ? "Annual" : "Monthly")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        if isAnnual {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green))
                        }
                    }
                    Text(isAnnual ? "7-day free trial, then \(product.displayPrice)/year" : "\(product.displayPrice)/month · Try 7 days free")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Spacer()

                if isAnnual {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(product.displayPrice)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ year")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(product.displayPrice)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ month")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    guard let product = subscriptionManager.products.first(where: { $0.id == selectedProduct }) else { return }
                    await subscriptionManager.purchase(product)
                    if subscriptionManager.isPro { dismiss() }
                }
            } label: {
                Group {
                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(height: 20)
                    } else {
                        Text("Start Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.35), radius: 16, x: 0, y: 6)
                }
                .foregroundStyle(.white)
            }
            .disabled(subscriptionManager.isPurchasing)
            .padding(.horizontal, 20)

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("Cancel anytime. Subscription auto-renews unless cancelled 24h before renewal.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://nexusshield.app/privacy")!)
                Link("Terms of Use", destination: URL(string: "https://nexusshield.app/terms")!)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }
}
