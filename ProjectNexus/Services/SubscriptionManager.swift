import Foundation
import StoreKit
import os

@MainActor
@Observable
final class SubscriptionManager {
    private(set) var isPro: Bool = false
    private(set) var isLoading: Bool = false

    private let productID = "com.nexus.projectnexus.pro"
    private let logger = Logger(subsystem: "com.nexus.store", category: "IAP")
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await restorePurchases() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func purchase() async throws {
        isLoading = true
        defer { isLoading = false }

        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            logger.warning("Pro product not found in App Store")
            return
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            await transaction.finish()
            isPro = true
            logger.info("Pro purchased successfully")
        case .userCancelled:
            logger.info("Purchase cancelled by user")
        case .pending:
            logger.info("Purchase pending (Ask to Buy or SCA)")
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                isPro = true
                logger.info("Pro entitlement restored")
                return
            }
        }
        logger.info("No Pro entitlement found")
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == self.productID,
                   transaction.revocationDate == nil {
                    await MainActor.run { self.isPro = true }
                    await transaction.finish()
                }
            }
        }
    }
}
