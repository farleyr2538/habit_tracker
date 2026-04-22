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
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPaywall = false
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    @State private var showMigrationDebug = false
    @State private var showStorageLocationDebug = false
    @State private var cloudSyncDisabled = UserDefaults.standard.bool(forKey: "cloudSyncDisabled")
    @State private var showRestartAlert = false
    @State private var showMergeHabits = false
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
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
                        get: { subscriptionManager.isPremium && !cloudSyncDisabled },
                        set: { newValue in
                            if subscriptionManager.isPremium {
                                let willEnableSync = newValue
                                let currentSyncState = !cloudSyncDisabled
                                
                                // Only allow change if it's different from current state
                                if willEnableSync != currentSyncState {
                                    cloudSyncDisabled = !newValue
                                    UserDefaults.standard.set(cloudSyncDisabled, forKey: "cloudSyncDisabled")
                                    showRestartAlert = true
                                }
                            }
                        }
                    )) {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                    .disabled(!subscriptionManager.isPremium)
                    .onTapGesture {
                        if !subscriptionManager.isPremium {
                            showPaywall = true
                        }
                    }
                    
                    if !cloudSyncDisabled && subscriptionManager.isPremium {
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
                    Text("Settings")
                } footer: {
                    /* if !subscriptionManager.isPremium {
                        Text("iCloud Sync is a premium feature. Upgrade to Habit Tracker Pro to automatically sync your habits across all your devices.")
                    } else */ if cloudSyncDisabled {
                        Text("iCloud Sync is disabled. Your habits are stored locally on this device only.")
                    } else {
                        Text("Your habits automatically sync across all your devices signed into the same iCloud account. Data is backed up and will restore when you reinstall the app.")
                    }
                }
                
                Section {
                    Button {
                        showMergeHabits = true
                    } label: {
                        Label("Merge Habits", systemImage: "arrow.triangle.merge")
                    }
                } header: {
                    Text("Merge")
                } footer: {
                    Text("Combine multiple habits into one. All completion dates will be preserved.")
                }
                
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
                                Text("Unlock unlimited habits and much more")
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
                
                #if DEBUG
                // Storage location debugging (available in all builds)
                Section {
                    Button {
                        showStorageLocationDebug = true
                    } label: {
                        Label("Check Storage Locations", systemImage: "folder.badge.questionmark")
                    }
                    
                    Button {
                        printCloudKitSyncDebug()
                    } label: {
                        Label("Print CloudKit Sync Debug", systemImage: "icloud.and.arrow.down")
                    }
                } header: {
                    Text("Troubleshooting")
                } footer: {
                    Text("Use these tools to diagnose sync issues. The CloudKit debug will print a detailed report to the Xcode console showing all habits and their sync status.")
                }
                
                // Debug section (for troubleshooting migration issues)
                
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
            .alert("App Restart Required", isPresented: $showRestartAlert) {
                Button("I Understand", role: .cancel) {
                    // Dismiss the entire settings view to force user to restart
                    dismiss()
                }
            } message: {
                Text("To apply this change, you MUST force quit the app and reopen it:\n\n1. Swipe up from bottom of screen (or double-click home button)\n2. Swipe up on Habit Tracker to close it\n3. Tap the app icon to reopen\n\nThe setting will not take effect until you restart.")
            }
            .task {
                // Check if sync should be automatically disabled when subscription expires
                checkAndUpdateSyncStatus()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet_SubscriptionStoreView()
                .environment(subscriptionManager)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showMigrationDebug) {
            MigrationDebugView()
                .environment(subscriptionManager)
                .environment(cloudKitMonitor)
                .environment(viewModel)
        }
        .sheet(isPresented: $showStorageLocationDebug) {
            StorageLocationDebugView()
                .environment(subscriptionManager)
                .environment(cloudKitMonitor)
                .environment(viewModel)
        }
        .sheet(isPresented: $showMergeHabits) {
            MergeHabitsView()
                .environment(viewModel)
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
    
    private func printCloudKitSyncDebug() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            // Use the ViewModel from the environment (not creating a new instance)
            // Add safety check in case environment isn't properly set up
            guard let vm = try? viewModel as? ViewModel else {
                debugMessage = "⚠️ ViewModel not available in environment. This shouldn't happen."
                showDebugAlert = true
                return
            }
            
            vm.debugCloudKitSync(habits: habits, context: modelContext)
            
            debugMessage = "✅ CloudKit sync debug report printed to console. Check Xcode's console to view the detailed report."
            showDebugAlert = true
            
        } catch {
            debugMessage = "❌ Failed to fetch habits: \(error.localizedDescription)"
            showDebugAlert = true
        }
    }
    
    private func resetMigrationFlags() {
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.migrationCompleteKey)
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.schemaMigrationVerifiedKey)
        
        debugMessage = "Migration flags have been reset. Restart the app to re-run migrations."
        showDebugAlert = true
    }
    
    /// Check if iCloud sync should be automatically disabled due to subscription expiration
    private func checkAndUpdateSyncStatus() {
        // If user is not premium but sync is enabled, automatically disable it
        if !subscriptionManager.isPremium && !cloudSyncDisabled {
            cloudSyncDisabled = true
            UserDefaults.standard.set(true, forKey: "cloudSyncDisabled")
            print("⚠️ Automatically disabled iCloud sync - premium subscription required")
        }
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionManager())
        .environment(CloudKitSyncMonitor())
        .environment(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true)
}
