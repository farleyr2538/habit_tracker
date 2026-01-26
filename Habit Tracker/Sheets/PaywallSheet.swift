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
        
        VStack(spacing: 30) {
            Text("This is a Premium feature")
            
            Text("Upgrade now to access it")
            
            HStack(spacing: 40) {
                Button("£1.99 per month") {
                    Task {
                        try await subscriptionManager.purchase(productID: ProductID.premiumMonthly)
                    }
                    
                }
                
                Button("£99 per year") {
                    Task {
                        try await subscriptionManager.purchase(productID: ProductID.premiumAnnual)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
}

#Preview {
    PaywallSheet()
        .environment(SubscriptionManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
