//
//  SettingsView.swift
//  Habit Tracker
//
//  Created by Robert Farley on 17/03/2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription section
                Section {
                    if subscriptionManager.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Habit Tracker Pro")
                                .font(.headline)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Manage Subscription") {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                Task {
                                    do {
                                        try await AppStore.showManageSubscriptions(in: windowScene)
                                    } catch {
                                        print("Failed to show manage subscriptions: \(error)")
                                    }
                                }
                            }
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upgrade to Pro")
                                    .font(.headline)
                                Text("Unlock unlimited habits, widgets, and more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPaywall = true
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
                .presentationBackground(.ultraThinMaterial)
        }
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager())
}
