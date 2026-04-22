//
//  PaywallSheet.swift
//  Habit Tracker
//
//  Created by Rob Farley on 21/01/2026.
//

import SwiftUI
import StoreKit

/*
struct PaywallSheet: View {
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isPurchasing = false
    @State private var showErrorAlert = false
    @State private var useBuiltInView = true // Toggle to use SubscriptionStoreView
    
    enum SubscriptionPlan {
        case monthly
        case yearly
    }
    
    // MARK: - Computed Properties
    
    private var monthlyProduct: StoreKit.Product? {
        subscriptionManager.monthlyProduct
    }
    
    private var yearlyProduct: StoreKit.Product? {
        subscriptionManager.yearlyProduct
    }
    
    private var selectedProductID: String {
        selectedPlan == .yearly ? ProductID.premiumAnnual : ProductID.premiumMonthly
    }
    
    // Dynamically get trial info text
    private var trialInfoText: String {
        if let product = selectedPlan == .yearly ? yearlyProduct : monthlyProduct {
            return subscriptionManager.fullPricingText(for: product)
        }
        // Fallback text
        return "Subscribe to unlock premium features"
    }
    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 0) {
                
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 15)
                
                // Loading indicator
                if subscriptionManager.isLoading {
                    ProgressView()
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                }
                
                // Illustration
                Image(systemName: "crown.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.yellow)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                
                // Title
                Text("Get Habit Tracker Pro")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                // Features list
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "plus.square", text: "Unlimited Habits")
                    /*FeatureRow(icon: "widget.small", text: "Widgets")*/
                    FeatureRow(icon: "paintpalette", text: "Custom Habit Colours")
                    FeatureRow(icon: "7.calendar", text: "7 Day Free Trial")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                
                // Subscription options
                if !subscriptionManager.isLoading {
                    HStack(spacing: 12) {
                        // Monthly option
                        SubscriptionCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            title: "Monthly",
                            price: monthlyProduct?.displayPrice ?? "$1.99",
                            period: "/mo",
                            badge: nil
                        ) {
                            selectedPlan = .monthly
                        }
                        
                        // Yearly option
                        SubscriptionCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            title: "Yearly",
                            price: yearlyProduct?.displayPrice ?? "$19.99",
                            period: "/yr",
                            badge: "Save 20%"
                        ) {
                            selectedPlan = .yearly
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                // Continue button
                Button {
                    handlePurchase()
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(isPurchasing ? "Processing..." : "Try a 7 day free trial")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accent)
                    )
                }
                .disabled(isPurchasing || subscriptionManager.isLoading)
                .opacity(isPurchasing || subscriptionManager.isLoading ? 0.6 : 1.0)
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                /*
                // Trial info - Dynamic!
                Text(trialInfoText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                 */
                
                // Restore purchases button
                Button {
                    handleRestore()
                } label: {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 5)
                .padding(.bottom, 16)
                
                // Required links for App Review
                HStack(spacing: 20) {
                    Link("Terms of Use", destination: URL(string: "https://yourwebsite.com/terms")!)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 30)
            }
        }
        .interactiveDismissDisabled()
        .alert("Purchase Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = subscriptionManager.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            // Load products when the sheet appears
            if subscriptionManager.availableProducts.isEmpty {
                await subscriptionManager.loadProducts()
            }
            
            print("📦 Available products: \(subscriptionManager.availableProducts.count)")
            for product in subscriptionManager.availableProducts {
                print("  - \(product.id): \(product.displayPrice)")
            }
            print("📱 Monthly product: \(monthlyProduct?.id ?? "nil")")
            print("📅 Yearly product: \(yearlyProduct?.id ?? "nil")")
        }
    }
    
    // MARK: - Actions
    
    private func handlePurchase() {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchase(productID: selectedProductID)
                
                // Dismiss on successful purchase
                if subscriptionManager.isPremium {
                    dismiss()
                }
            } catch {
                // Show error alert
                showErrorAlert = true
            }
            
            isPurchasing = false
        }
    }
    
    private func handleRestore() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                
                // Dismiss if premium was restored
                if subscriptionManager.isPremium {
                    dismiss()
                }
            } catch {
                showErrorAlert = true
            }
            subscriptionManager.isLoading = false
        }
    }
}


#Preview {
    PaywallSheet()
        .environment(SubscriptionManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
*/
