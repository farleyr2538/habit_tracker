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

@Observable
class SubscriptionManager {
    
    var isPremium : Bool = false
    
    func checkSubscriptionStatus() async {
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProductID.premiumMonthly || transaction.productID == ProductID.premiumAnnual {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
    }
    
    func purchase(productID: String) async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { return }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await checkSubscriptionStatus()
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
}
