//
//  SubscriptionManager.swift
//  Habit Tracker
//
//  Created by Rob Farley on 21/01/2026.
//

import Foundation
import StoreKit

enum ProductID {
    static let premiumMonthly = "com.rob.habitTracker.premiumMonthly"
    static let premiumAnnual = "com.rob.habitTracker.premiumAnnual"
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case noProductsAvailable
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription not available. Please try again later."
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Unable to verify purchase. Please contact support."
        case .noProductsAvailable:
            return "No subscription products available. Please check your connection and try again."
        }
    }
}

@Observable
class SubscriptionManager {
    
    var isPremium: Bool = false
    var availableProducts: [StoreKit.Product] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Computed Properties for Easy Access
    
    var monthlyProduct: StoreKit.Product? {
        availableProducts.first { $0.id == ProductID.premiumMonthly }
    }
    
    var yearlyProduct: StoreKit.Product? {
        availableProducts.first { $0.id == ProductID.premiumAnnual }
    }
    
    // MARK: - Initialization
    
    init() {
        // Start observing transaction updates when initialized
        Task {
            await observeTransactionUpdates()
        }
    }
    
    // MARK: - Load Products
    
    // Load available subscription products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            availableProducts = try await StoreKit.Product.products(
                for: [ProductID.premiumMonthly, ProductID.premiumAnnual]
            )
            
            if availableProducts.isEmpty {
                errorMessage = SubscriptionError.noProductsAvailable.errorDescription
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Check Subscription Status
    
    /// Check for premium subscription status
    /// Note: This is now async as StoreKit 2 requires async operations
    static func hasPremiumSubscription() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            switch entitlement {
            case .verified(let transaction):
                if transaction.productID == ProductID.premiumMonthly || 
                   transaction.productID == ProductID.premiumAnnual {
                    return true
                }
            case .unverified:
                // Ignore unverified transactions
                break
            }
        }
        return false
    }
    
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == ProductID.premiumMonthly || 
                   transaction.productID == ProductID.premiumAnnual {
                    isPremium = true
                    // Cache the premium status for synchronous access during app initialization
                    UserDefaults.standard.set(true, forKey: "cachedPremiumStatus")
                    return
                }
            case .unverified:
                // Ignore unverified transactions
                break
            }
        }
        isPremium = false
        // Cache the non-premium status
        UserDefaults.standard.set(false, forKey: "cachedPremiumStatus")
    }
    
    // MARK: - Purchase
    
    func purchase(productID: String) async throws {
        errorMessage = nil
        
        // Find the product
        guard let product = availableProducts.first(where: { $0.id == productID }) else {
            errorMessage = SubscriptionError.productNotFound.errorDescription
            throw SubscriptionError.productNotFound
        }
        
        // Attempt purchase
        let result: StoreKit.Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            errorMessage = SubscriptionError.purchaseFailed(error).errorDescription
            throw SubscriptionError.purchaseFailed(error)
        }
        
        // Handle purchase result
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                // Transaction is verified, unlock content
                await transaction.finish()
                await checkSubscriptionStatus()
                
            case .unverified(_, let verificationError):
                // Transaction failed verification
                errorMessage = SubscriptionError.verificationFailed.errorDescription
                print("Transaction verification failed: \(verificationError)")
                throw SubscriptionError.verificationFailed
            }
            
        case .userCancelled:
            // User cancelled the purchase, no error needed
            break
            
        case .pending:
            // Purchase is pending (e.g., Ask to Buy for family sharing)
            errorMessage = "Purchase is pending approval."
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases (useful when switching devices)
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Observe Transaction Updates
    
    /// Observe transaction updates for renewals, expirations, or refunds
    private func observeTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            switch verificationResult {
            case .verified(let transaction):
                // A transaction was updated (renewed, expired, refunded, etc.)
                await transaction.finish()
                await checkSubscriptionStatus()
            case .unverified:
                // Ignore unverified transactions
                break
            }
        }
    }
    
    // MARK: - Helper Methods for Rich Subscription Info
    
    /// Get formatted subscription period (e.g., "1 month", "1 year")
    func subscriptionPeriod(for product: StoreKit.Product) -> String? {
        guard let subscription = product.subscription else { return nil }
        
        let value = subscription.subscriptionPeriod.value
        let unit = subscription.subscriptionPeriod.unit
        
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return nil
        }
    }
    
    /// Get introductory offer description (e.g., "3-day free trial")
    func introductoryOfferDescription(for product: StoreKit.Product) -> String? {
        guard let subscription = product.subscription,
              let intro = subscription.introductoryOffer else {
            return nil
        }
        
        let value = intro.period.value
        let unit = intro.period.unit
        
        var periodString: String
        switch unit {
        case .day:
            periodString = value == 1 ? "day" : "\(value) days"
        case .week:
            periodString = value == 1 ? "week" : "\(value) weeks"
        case .month:
            periodString = value == 1 ? "month" : "\(value) months"
        case .year:
            periodString = value == 1 ? "year" : "\(value) years"
        @unknown default:
            periodString = "\(value) periods"
        }
        
        switch intro.paymentMode {
        case .freeTrial:
            return "\(periodString) free trial"
        case .payAsYouGo:
            return "\(intro.displayPrice) for \(periodString)"
        case .payUpFront:
            return "\(intro.displayPrice) for \(periodString)"
        default:
            // Handle any unknown payment modes gracefully
            return nil
        }
    }
    
    /// Get full trial and pricing text (e.g., "3-day free trial, then £19.99/year")
    func fullPricingText(for product: StoreKit.Product) -> String {
        var components: [String] = []
        
        // Add introductory offer if available
        if let introText = introductoryOfferDescription(for: product) {
            components.append(introText)
        }
        
        // Add regular price with period
        if let period = subscriptionPeriod(for: product) {
            let priceText = components.isEmpty ? 
                "\(product.displayPrice)/\(period)" : 
                "then \(product.displayPrice)/\(period)"
            components.append(priceText)
        } else {
            components.append(product.displayPrice)
        }
        
        return components.joined(separator: ", ")
    }
    
}
