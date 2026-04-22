//
//  PaywallSheet_SubscriptionStoreView.swift
//  Habit Tracker
//
//  Alternative paywall using Apple's SubscriptionStoreView
//  This automatically includes all required links for App Review
//

import SwiftUI
import StoreKit

struct PaywallSheet_SubscriptionStoreView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    var body: some View {
        SubscriptionStoreView(groupID: "21977620") {
            
            // Custom marketing content at the top
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                
                Text("Get Habit Tracker Pro")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "plus.square", text: "Unlimited Habits")
                    FeatureRow(icon: "icloud", text: "iCloud Sync")
                    FeatureRow(icon: "paintpalette", text: "Change Habit Colours")
                    FeatureRow(icon: "7.calendar", text: "7 Day Free Trial")
                    //FeatureRow(icon: "widget.small", text: "Widgets")
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 50)
            //.padding(.bottom, 20)
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .subscriptionStorePolicyDestination(url: URL(string: "https://drive.google.com/uc?export=view&id=16IIY7iMuPPeQ_IbCkGFrr5-6SIlfYE2k")!, for: .termsOfService)
        
        .subscriptionStorePolicyDestination(url: URL(string: "https://drive.google.com/uc?export=view&id=1oYbQ7QuLGvCxkhuDWGRwyGbVYbmVoGLr")!, for: .privacyPolicy)
        .onInAppPurchaseCompletion { product, result in
            if case .success(.success(_)) = result {
                // Update subscription status immediately
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                    // Dismiss after status is updated
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    PaywallSheet_SubscriptionStoreView()
        .environment(SubscriptionManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
