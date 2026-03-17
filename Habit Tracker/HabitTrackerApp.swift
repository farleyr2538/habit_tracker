//
//  HabitTracker.swift
//  Habit Tracker
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - App Group Migration Helper
struct AppGroupMigration {
    static let migrationCompleteKey = "appGroupMigrationCompleted"
    
    /// Migrates data from the old default location to the App Group container
    /// Returns true if migration was needed and completed, false if already migrated
    static func migrateToAppGroupIfNeeded(appGroupID: String, newStoreURL: URL) -> Bool {
        // Check if we've already migrated
        if UserDefaults.standard.bool(forKey: migrationCompleteKey) {
            print("✅ App Group migration already completed")
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
            
            // If data already exists at new location, we need to decide what to do
            if FileManager.default.fileExists(atPath: newStoreURL.path) {
                print("⚠️ Data already exists at new location")
                
                // Compare TOTAL file sizes (main store + WAL + SHM) to determine which has more data
                let oldTotalSize = calculateTotalStoreSize(storeURL: oldStoreURL)
                let newTotalSize = calculateTotalStoreSize(storeURL: newStoreURL)
                
                print("📊 Old location total size: \(oldTotalSize) bytes")
                print("📊 New location total size: \(newTotalSize) bytes")
                
                // If old location has significantly more data (more than 10KB difference), replace the new one
                if oldTotalSize > newTotalSize + 10_000 {
                    print("🔄 Old data appears to have more content - replacing new location with old data")
                    
                    // Delete the empty/smaller files at new location
                    let newDirectory = newStoreURL.deletingLastPathComponent()
                    let storeName = newStoreURL.lastPathComponent
                    let relatedFiles = [storeName, storeName + "-wal", storeName + "-shm"]
                    
                    for fileName in relatedFiles {
                        let fileToDelete = newDirectory.appending(path: fileName)
                        if FileManager.default.fileExists(atPath: fileToDelete.path) {
                            try? FileManager.default.removeItem(at: fileToDelete)
                            print("🗑️ Deleted existing: \(fileName)")
                        }
                    }
                    
                    // Now copy the old data over
                    try copyStoreFiles(from: oldStoreURL, to: newStoreURL)
                    print("✅ Migration completed successfully!")
                    UserDefaults.standard.set(true, forKey: migrationCompleteKey)
                    return true
                    
                } else {
                    print("✅ New location has sufficient data - assuming migration already complete")
                    UserDefaults.standard.set(true, forKey: migrationCompleteKey)
                    return false
                }
            }
            
            // New location doesn't exist, so do a clean copy
            try copyStoreFiles(from: oldStoreURL, to: newStoreURL)
            
            print("✅ Migration completed successfully!")
            
            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            
            // Optionally, delete old files to free up space
            // Uncomment if you want to clean up:
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



@main
struct HabitTrackerApp : App {
    
    @StateObject var viewModel = ViewModel()
    
    @State private var subscriptionManager = SubscriptionManager()
    
    let container : ModelContainer
    let migrationError: Error?
    
    init() {
        // initialize modelContainer

        let schema = Schema([
            Habit.self
        ])

        // Use shared app group container so widget can access the same data
        let appGroupID = "group.com.rob.habittracker"
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("❌ Could not access App Group container - make sure '\(appGroupID)' is enabled in capabilities!")
        }
        
        let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")
        
        // Migrate existing data to App Group if this is the first launch after update
        let didMigrate = AppGroupMigration.migrateToAppGroupIfNeeded(
            appGroupID: appGroupID,
            newStoreURL: storeURL
        )
        if didMigrate {
            print("📱 Data migrated to App Group - widgets will now work!")
        }
         
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )

        let migrationPlan = MigrationPlan.self

        var tempContainer: ModelContainer?
        var tempError: Error?
        
        do {
            tempContainer = try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan,
                configurations: [modelConfiguration]
            )
            
            print("ModelContainer initialization succeeded!")
            
        } catch {
            print("⚠️ ModelContainer initialization failed: \(error)")
            tempError = error
            
            // Create a fallback in-memory container so the app doesn't crash
            do {
                tempContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: migrationPlan,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            } catch {
                fatalError("Could not initialize even fallback ModelContainer: \(error)")
            }
        }
        
        self.container = tempContainer!
        self.migrationError = tempError
    }
    
    var body: some Scene {
        
        WindowGroup {
            if let error = migrationError {
                MigrationErrorView(error: error)
                    .environment(subscriptionManager)
                    .environmentObject(viewModel)
            } else {
                ContentView()
                    .environment(subscriptionManager)
                    .environmentObject(viewModel)
                    .modelContainer(container)
                    .task {
                        // Check subscription status and load products on app launch
                        await subscriptionManager.checkSubscriptionStatus()
                        await subscriptionManager.loadProducts()
                    }
            }
        }
    }
}
