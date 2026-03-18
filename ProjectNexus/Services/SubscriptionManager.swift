import Foundation
import StoreKit
import os

// MARK: - Product IDs
// CEO decision: $3.99/month, $19.99/year, 7-day free trial

enum NexusProduct: String, CaseIterable {
    case monthly = "com.nexus.shield.monthly"
    case annual  = "com.nexus.shield.annual"
}

// MARK: - SubscriptionManager

/// Manages StoreKit 2 subscriptions and entitlement state.
///
/// Free tier:  Tier 1 acoustic shield only.
/// Pro tier:   Tier 2 UAP adversarial + Session History + Diagnostics.
@MainActor
@Observable
final class SubscriptionManager {

    // MARK: - Public state

    /// True when the user has an active Pro subscription.
    private(set) var isPro: Bool = false

    /// Products fetched from the App Store.
    private(set) var products: [Product] = []

    /// True while a purchase or restore is in progress.
    private(set) var isPurchasing: Bool = false

    /// Non-nil when a purchase error occurred.
    private(set) var purchaseError: String? = nil

    // MARK: - Private

    private let logger = Logger(subsystem: "com.nexus.store", category: "Subscriptions")
    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshEntitlement() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlement()
                logger.info("Purchase succeeded: \(product.id)")
            case .pending:
                logger.info("Purchase pending: \(product.id)")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
            logger.error("Purchase failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            logger.info("Restore completed")
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    private func loadProducts() async {
        do {
            let fetched = try await Product.products(for: NexusProduct.allCases.map(\.rawValue))
            products = fetched.sorted { $0.price < $1.price }
            logger.info("Loaded \(self.products.count) products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    private func refreshEntitlement() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               NexusProduct(rawValue: transaction.productID) != nil,
               transaction.revocationDate == nil {
                hasPro = true
                break
            }
        }
        isPro = hasPro
        logger.info("Entitlement refresh: isPro=\(hasPro)")
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.refreshEntitlement()
                    await transaction.finish()
                } catch {
                    self.logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
