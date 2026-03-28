//
//  SettingsView.swift
//  Habit Tracker
//
//  Created by Robert Farley on 17/03/2026.
//

import SwiftUI
import StoreKit
import SwiftData

struct SettingsView: View {
    
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(CloudKitSyncMonitor.self) private var cloudKitMonitor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPaywall = false
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    @State private var showMigrationDebug = false
    @State private var showStorageLocationDebug = false
    @State private var cloudSyncDisabled = UserDefaults.standard.bool(forKey: "cloudSyncDisabled")
    @State private var showRestartAlert = false
    
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
                
                // iCloud Sync section
                Section {
                    Toggle(isOn: Binding(
                        get: { !cloudSyncDisabled },
                        set: { newValue in
                            cloudSyncDisabled = !newValue
                            UserDefaults.standard.set(cloudSyncDisabled, forKey: "cloudSyncDisabled")
                            showRestartAlert = true
                        }
                    )) {
                        Label("Enable iCloud Sync", systemImage: "icloud")
                    }
                    
                    if !cloudSyncDisabled {
                        HStack {
                            Text("Status")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if cloudKitMonitor.isSyncing {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Syncing...")
                                        .font(.caption)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                    Text("Up to date")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        if let lastSync = cloudKitMonitor.lastSyncDate {
                            HStack {
                                Text("Last Sync")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        if let error = cloudKitMonitor.lastSyncError {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Sync Issue", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    if cloudSyncDisabled {
                        Text("iCloud Sync is disabled. Your habits are stored locally on this device only.")
                    } else {
                        Text("Your habits automatically sync across all your devices signed into the same iCloud account. Data is backed up and will restore when you reinstall the app.")
                    }
                }
                
                // Storage location debugging (available in all builds)
                Section {
                    Button {
                        showStorageLocationDebug = true
                    } label: {
                        Label("Check Storage Locations", systemImage: "folder.badge.questionmark")
                    }
                } header: {
                    Text("Troubleshooting")
                } footer: {
                    Text("If habits appear to be missing after an update, use this tool to check all possible storage locations where your data might exist.")
                }
                
                // Debug section (for troubleshooting migration issues)
                #if DEBUG
                Section {
                    Button("Open Migration Debug Tools") {
                        showMigrationDebug = true
                    }
                                        
                    Button("Quick: Verify Data Migration") {
                        verifyDataMigration()
                    }
                    
                    Button("Quick: Reset Migration Flags") {
                        resetMigrationFlags()
                    }
                    .foregroundStyle(.red)
                } header: {
                    Text("Advanced Debug Tools")
                } footer: {
                    Text("⚠️ Developer tools for testing migrations and creating test data.")
                }
                #endif
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
            .alert("Migration Status", isPresented: $showDebugAlert) {
                Button("OK") { }
            } message: {
                Text(debugMessage)
            }
            .alert("Restart Required", isPresented: $showRestartAlert) {
                Button("OK") { }
            } message: {
                Text("Please force quit and reopen the app for the iCloud sync setting to take effect.")
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet_SubscriptionStoreView()
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showMigrationDebug) {
            MigrationDebugView()
        }
        .sheet(isPresented: $showStorageLocationDebug) {
            StorageLocationDebugView()
        }
    }
    
    private func verifyDataMigration() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            let orders = habits.map { $0.order }
            let uniqueOrders = Set(orders)
            let hasDuplicates = uniqueOrders.count != habits.count
            
            if hasDuplicates {
                // Fix duplicate orders
                let sortedHabits = habits.sorted { $0.dateCreated < $1.dateCreated }
                for (index, habit) in sortedHabits.enumerated() {
                    habit.order = index
                }
                try modelContext.save()
                
                debugMessage = "Found and fixed issues with \(habits.count) habits. Order values have been corrected."
            } else {
                debugMessage = "Verification passed! Found \(habits.count) habits with correct order values."
            }
            
            showDebugAlert = true
            
        } catch {
            debugMessage = "Verification failed: \(error.localizedDescription)"
            showDebugAlert = true
        }
    }
    
    private func resetMigrationFlags() {
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.migrationCompleteKey)
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.schemaMigrationVerifiedKey)
        
        debugMessage = "Migration flags have been reset. Restart the app to re-run migrations."
        showDebugAlert = true
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager())
        .environment(CloudKitSyncMonitor())
        .modelContainer(for: Habit.self, inMemory: true)
}
