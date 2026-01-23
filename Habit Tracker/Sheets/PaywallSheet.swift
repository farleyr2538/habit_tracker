//
//  PaywallSheet.swift
//  Habit Tracker
//
//  Created by Rob Farley on 21/01/2026.
//

import SwiftUI

struct PaywallSheet: View {
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    
    var body: some View {
        
        Button("Pay monthly") {
            
            Task {
                try await subscriptionManager.purchase(productID: ProductID.premiumMonthly)
            }
            
        }
        
    }
    
}

#Preview {
    PaywallSheet()
        .environment(SubscriptionManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
