//
//  HabitTracker.swift
//  Habit Tracker
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - CloudKit Sync Monitor
@Observable
class CloudKitSyncMonitor {
    var isSyncing = false
    var lastSyncError: Error?
    var lastSyncDate: Date?
    
    @MainActor
    func monitorSync(container: ModelContainer) {
        // Monitor ModelContext changes to track sync activity
        NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isSyncing = true
            self.lastSyncDate = Date()
            
            // Reset syncing indicator after a brief delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                self.isSyncing = false
            }
        }
        
        print("☁️ CloudKit sync monitoring enabled")
    }
}

// MARK: - App Group Migration Helper
struct AppGroupMigration {
    static let migrationCompleteKey = "appGroupMigrationCompleted"
    static let schemaMigrationVerifiedKey = "schemaMigrationVerified_v3"
    
    /// Verifies that habits exist and have proper order values
    /// Returns true if verification passed, false if issues were found
    @MainActor
    static func verifyMigration(container: ModelContainer) -> Bool {
        do {
            let context = container.mainContext
            let descriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(descriptor)
            
            print("🔍 Migration verification: Found \(habits.count) habits")
            
            // Check if any habits have missing or duplicate order values
            let orders = habits.map { $0.order }
            let uniqueOrders = Set(orders)
            
            if habits.count > 0 && uniqueOrders.count != habits.count {
                print("⚠️ Found duplicate order values - fixing...")
                
                // Re-assign order values
                let sortedHabits = habits.sorted { $0.dateCreated < $1.dateCreated }
                for (index, habit) in sortedHabits.enumerated() {
                    habit.order = index
                }
                
                try context.save()
                print("✅ Fixed order values for \(habits.count) habits")
            }
            
            UserDefaults.standard.set(true, forKey: schemaMigrationVerifiedKey)
            return true
            
        } catch {
            print("❌ Migration verification failed: \(error)")
            return false
        }
    }
    
    /// Migrates data from the old default location to the App Group container
    /// Returns true if migration was needed and completed, false if already migrated
    static func migrateToAppGroupIfNeeded(appGroupID: String, newStoreURL: URL) -> Bool {
        // Check if we've already migrated
        if UserDefaults.standard.bool(forKey: migrationCompleteKey) {
            print("✅ App Group migration already completed")
            return false
        }
        
        // SAFETY CHECK #1: If new location already has ANY data, DON'T migrate
        // This is the safest approach - never overwrite existing data
        if FileManager.default.fileExists(atPath: newStoreURL.path) {
            let newTotalSize = calculateTotalStoreSize(storeURL: newStoreURL)
            
            // Even if it's a small file, if it exists, we preserve it
            print("⚠️ New location already exists (\(newTotalSize) bytes)")
            print("⚠️ SAFETY MODE: Preserving existing data, skipping migration")
            print("⚠️ Marking migration as complete to prevent future attempts")
            print("⚠️ NOTE: Use the Storage Locations tool to manually merge any old habits")
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            return false
        }
        
        // Get the old default store location
        let oldStoreURL = URL.applicationSupportDirectory.appending(path: "default.store")
        
        print("🔍 Checking for old data at: \(oldStoreURL.path)")
        print("🎯 New location will be: \(newStoreURL.path)")
        
        // Check if old data exists
        guard FileManager.default.fileExists(atPath: oldStoreURL.path) else {
            print("ℹ️ No old data found - this might be a fresh install")
            // Mark as migrated so we don't check again
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            return false
        }
        
        print("📦 Found old data - starting migration...")
        
        do {
            // Ensure the App Group container directory exists
            let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            try FileManager.default.createDirectory(at: appGroupContainer, withIntermediateDirectories: true)
            
            // Since we already checked above, new location doesn't exist
            // Do a clean copy from old to new
            try copyStoreFiles(from: oldStoreURL, to: newStoreURL)
            
            print("✅ Migration completed successfully!")
            print("   Copied data from old location to App Group")
            
            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            
            // Optionally, delete old files to free up space
            // Uncomment if you want to clean up after successful migration:
            /*
            let oldDirectory = oldStoreURL.deletingLastPathComponent()
            let storeName = oldStoreURL.lastPathComponent
            let relatedFiles = [storeName, storeName + "-wal", storeName + "-shm"]
            for fileName in relatedFiles {
                let oldFile = oldDirectory.appending(path: fileName)
                if FileManager.default.fileExists(atPath: oldFile.path) {
                    try? FileManager.default.removeItem(at: oldFile)
                }
            }
            print("🗑️ Cleaned up old data files")
            */
            
            return true
            
        } catch {
            print("❌ Migration failed: \(error)")
            // Don't mark as complete so we can try again next launch
            return false
        }
    }
    
    /// Helper function to copy all store-related files
    private static func copyStoreFiles(from oldStoreURL: URL, to newStoreURL: URL) throws {
        let oldDirectory = oldStoreURL.deletingLastPathComponent()
        let oldStoreName = oldStoreURL.lastPathComponent
        let newDirectory = newStoreURL.deletingLastPathComponent()
        let newStoreName = newStoreURL.lastPathComponent
        
        let relatedExtensions = ["", "-wal", "-shm"]
        
        for ext in relatedExtensions {
            let oldFile = oldDirectory.appending(path: oldStoreName + ext)
            let newFile = newDirectory.appending(path: newStoreName + ext)
            
            if FileManager.default.fileExists(atPath: oldFile.path) {
                try FileManager.default.copyItem(at: oldFile, to: newFile)
                print("✅ Copied: \(oldStoreName + ext) → \(newStoreName + ext)")
            }
        }
    }
    
    /// Helper function to calculate total size of all store-related files
    private static func calculateTotalStoreSize(storeURL: URL) -> Int {
        let directory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        let relatedFiles = [storeName, storeName + "-wal", storeName + "-shm"]
        
        var totalSize = 0
        for fileName in relatedFiles {
            let fileURL = directory.appending(path: fileName)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int {
                totalSize += size
            }
        }
        return totalSize
    }
}



// MARK: - Container Setup
// ModelContainer must NOT be created in the @main App struct's init() because
// Xcode previews crash (SIGTRAP) when Core Data is initialized that early.
// Using a @MainActor class with a lazy property defers creation until body evaluation.
@MainActor
final class AppContainerSetup {
    
    lazy var container: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let appGroupID = "group.com.rob.habittracker"
        
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("⚠️ App Group container not accessible - using in-memory fallback")
            // Use in-memory store WITHOUT migration plan for fallback scenarios
            // Use simple model array, not versioned schema, for maximum compatibility
            do {
                return try ModelContainer(
                    for: Habit.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                print("❌ FATAL: App Group fallback failed: \(error)")
                fatalError("Could not initialize even fallback ModelContainer: \(error)")
            }
        }
        
        let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")
        
        // Clean up any stale V4 migration flags (one-time cleanup)
        if !UserDefaults.standard.bool(forKey: "cleanedUpV4Flags") {
            UserDefaults.standard.removeObject(forKey: "migratedToV4CloudKitCompatible")
            UserDefaults.standard.removeObject(forKey: "cloudKitCompatibilityChecked_v4")
            UserDefaults.standard.set(true, forKey: "cleanedUpV4Flags")
            print("🧹 Cleaned up V4 migration flags")
        }
        
        // Migrate existing data to App Group if needed
        let didMigrate = AppGroupMigration.migrateToAppGroupIfNeeded(
            appGroupID: appGroupID,
            newStoreURL: storeURL
        )
        if didMigrate {
            print("📱 Data migrated to App Group - widgets will now work!")
        }
        
        // EMERGENCY RESET: Uncomment these lines if you need to delete corrupted database
        // This will delete the existing store and start fresh
        // DELETE THIS AFTER FIRST SUCCESSFUL RUN!
        /*
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try? FileManager.default.removeItem(at: storeURL)
            let walPath = storeURL.path + "-wal"
            let shmPath = storeURL.path + "-shm"
            if FileManager.default.fileExists(atPath: walPath) {
                try? FileManager.default.removeItem(atPath: walPath)
            }
            if FileManager.default.fileExists(atPath: shmPath) {
                try? FileManager.default.removeItem(atPath: shmPath)
            }
            print("🗑️ DELETED EXISTING DATABASE FOR FRESH START")
        }
        */
        
        // Configure CloudKit sync
        // Note: We check a cached premium status here because lazy properties cannot be async.
        // The actual subscription status will be verified in the app's .task modifier.
        let cloudSyncDisabled = UserDefaults.standard.bool(forKey: "cloudSyncDisabled")
        let cachedPremiumStatus = UserDefaults.standard.bool(forKey: "cachedPremiumStatus")
        
        let modelConfiguration: ModelConfiguration
        if cloudSyncDisabled || !cachedPremiumStatus {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL
            )
            if cloudSyncDisabled {
                print("💾 Using local-only storage (user disabled CloudKit)")
            } else if !cachedPremiumStatus {
                print("💾 Using local-only storage (premium required for CloudKit)")
            }
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private("iCloud.com.rob.habittracker")
            )
            print("☁️ CloudKit sync enabled (premium active)")
        }
        
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: [modelConfiguration]
            )
            
            // Verify habits are accessible
            let context = container.mainContext
            let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.dateCreated)])
            let habitCount = (try? context.fetchCount(descriptor)) ?? 0
            print("📊 Found \(habitCount) habits in the container")
            
            // Run migration verification to fix any order issues
            if !UserDefaults.standard.bool(forKey: AppGroupMigration.schemaMigrationVerifiedKey) {
                _ = AppGroupMigration.verifyMigration(container: container)
            }
            
            return container
        } catch {
            print("❌ ModelContainer initialization failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let swiftDataError = error as? any CustomStringConvertible {
                print("❌ SwiftData error description: \(swiftDataError)")
            }
            self.migrationError = error
            
            // Create a fallback in-memory container WITHOUT migration plan
            // Migration plans can fail with in-memory stores
            // Use simple model array, not versioned schema, for maximum compatibility
            do {
                print("⚠️ Attempting to create fallback in-memory container...")
                return try ModelContainer(
                    for: Habit.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                print("❌ FATAL: Fallback container also failed: \(error)")
                fatalError("Could not initialize even fallback ModelContainer: \(error)")
            }
        }
    }()
    
    var migrationError: Error?
}

@main
struct HabitTrackerApp : App {
    
    @State var viewModel = ViewModel()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var cloudKitMonitor = CloudKitSyncMonitor()
    @State private var containerSetup = AppContainerSetup()
    
    var body: some Scene {
        
        WindowGroup {
            if let error = containerSetup.migrationError {
                MigrationErrorView(error: error)
                    .environment(subscriptionManager)
                    .environment(cloudKitMonitor)
                    .environment(viewModel)
            } else {
                ContentView()
                    .environment(subscriptionManager)
                    .environment(cloudKitMonitor)
                    .environment(viewModel)
                    .modelContainer(containerSetup.container)
                    .task {
                        // Check subscription status and load products on app launch
                        await subscriptionManager.checkSubscriptionStatus()
                        await subscriptionManager.loadProducts()
                        
                        // Start monitoring CloudKit sync
                        cloudKitMonitor.monitorSync(container: containerSetup.container)
                    }
            }
        }
    }
}
