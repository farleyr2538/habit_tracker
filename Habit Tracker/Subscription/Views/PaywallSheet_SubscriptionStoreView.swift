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
                    FeatureRow(icon: "widget.small", text: "Widgets")
                    FeatureRow(icon: "paintpalette", text: "Custom Habit Colours")
                    FeatureRow(icon: "7.calendar", text: "7 Day Free Trial")
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .subscriptionStorePolicyDestination(url: URL(string: "https://drive.google.com/uc?export=view&id=16IIY7iMuPPeQ_IbCkGFrr5-6SIlfYE2k")!, for: .termsOfService)
        
        .subscriptionStorePolicyDestination(url: URL(string: "https://drive.google.com/uc?export=view&id=1oYbQ7QuLGvCxkhuDWGRwyGbVYbmVoGLr")!, for: .privacyPolicy)
        .onInAppPurchaseCompletion { product, result in
            if case .success(.success(_)) = result {
                dismiss()
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    PaywallSheet_SubscriptionStoreView()
        .modelContainer(for: Habit.self, inMemory: true)
}
