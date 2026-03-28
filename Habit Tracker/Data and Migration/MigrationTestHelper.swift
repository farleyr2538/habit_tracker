//
//  MigrationTestHelper.swift
//  Habit Tracker
//
//  Helper functions to create test databases at different schema versions
//

import Foundation
import SwiftData

struct MigrationTestHelper {
    
    /// Creates a V1 database at the specified URL for testing migrations
    @MainActor
    static func createV1TestDatabase(at url: URL) throws {
        // Clean up any existing database
        let directory = url.deletingLastPathComponent()
        let fileName = url.lastPathComponent
        for ext in ["", "-wal", "-shm"] {
            let fileURL = directory.appendingPathComponent(fileName + ext)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let schema = Schema([SchemaV1.Habit.self])
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [config]
        )
        
        let context = container.mainContext
        
        // Create realistic V1 test data
        let habit1 = SchemaV1.Habit(
            name: "Morning Exercise",
            dates: [
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!,
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 17))!,
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 20))!
            ],
            colorHash: "blue",
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!,
            startFrom: nil  // This is the key V1 issue - nil startFrom
        )
        
        let habit2 = SchemaV1.Habit(
            name: "Read Books",
            dates: [],
            colorHash: "green",
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 1, day: 12))!,
            startFrom: nil
        )
        
        let habit3 = SchemaV1.Habit(
            name: "Meditation",
            dates: [
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 11))!,
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 12))!,
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 13))!,
                calendar.date(from: DateComponents(year: 2024, month: 1, day: 14))!
            ],
            colorHash: nil,
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!,
            startFrom: nil  // Should become Jan 11 (earliest date)
        )
        
        context.insert(habit1)
        context.insert(habit2)
        context.insert(habit3)
        
        try context.save()
        
        print("✅ Created V1 test database at: \(url.path)")
        print("   - 3 habits with nil startFrom values")
        print("   - Ready for migration testing")
    }
    
    /// Creates a V2 database at the specified URL for testing V2→V3 migration
    @MainActor
    static func createV2TestDatabase(at url: URL) throws {
        // Clean up any existing database
        let directory = url.deletingLastPathComponent()
        let fileName = url.lastPathComponent
        for ext in ["", "-wal", "-shm"] {
            let fileURL = directory.appendingPathComponent(fileName + ext)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let schema = Schema([SchemaV2.Habit.self])
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [config]
        )
        
        let context = container.mainContext
        
        // Create V2 test data (no order property yet)
        let habit1 = SchemaV2.Habit(
            name: "Running",
            dates: [calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!],
            colorHash: "red",
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!,
            startFrom: calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        )
        
        let habit2 = SchemaV2.Habit(
            name: "Yoga",
            dates: [],
            colorHash: "purple",
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 2, day: 5))!,
            startFrom: calendar.date(from: DateComponents(year: 2024, month: 2, day: 5))!
        )
        
        let habit3 = SchemaV2.Habit(
            name: "Journaling",
            dates: [
                calendar.date(from: DateComponents(year: 2024, month: 2, day: 3))!,
                calendar.date(from: DateComponents(year: 2024, month: 2, day: 4))!
            ],
            colorHash: "orange",
            dateCreated: calendar.date(from: DateComponents(year: 2024, month: 2, day: 3))!,
            startFrom: calendar.date(from: DateComponents(year: 2024, month: 2, day: 3))!
        )
        
        context.insert(habit1)
        context.insert(habit2)
        context.insert(habit3)
        
        try context.save()
        
        print("✅ Created V2 test database at: \(url.path)")
        print("   - 3 habits without order property")
        print("   - Ready for V2→V3 migration testing")
    }
    
    /// Instructions for using this helper to test on device
    static func printTestingInstructions() {
        let instructions = """
        
        ═══════════════════════════════════════════════════════════
        📋 MIGRATION TESTING INSTRUCTIONS
        ═══════════════════════════════════════════════════════════
        
        METHOD 1: Use Xcode's Device Container Manager
        ───────────────────────────────────────────────────
        1. Build and run your app on a device/simulator
        2. In Xcode: Window → Devices and Simulators
        3. Select your device
        4. Find "Habit Tracker" in the list
        5. Click the gear icon → Download Container
        6. This downloads your current database
        
        To restore later:
        7. Click gear icon → Replace Container
        8. Choose the downloaded container
        
        METHOD 2: Use the Migration Debug View
        ───────────────────────────────────────────────────
        1. Build in DEBUG mode
        2. Go to Settings → Debug Tools
        3. Tap "Open Migration Debug Tools"
        4. Use the tools to:
           - Check current data
           - Create test habits
           - Verify migrations
           - Reset flags to re-test
        
        METHOD 3: Test with Automated Tests
        ───────────────────────────────────────────────────
        1. Open MigrationTests.swift
        2. Run the test suite (Cmd+U)
        3. Each test creates isolated databases
        4. Tests verify V1→V2, V2→V3, and full migrations
        
        METHOD 4: Manual Database Creation
        ───────────────────────────────────────────────────
        Add this to your app initialization (temporarily):
        
        #if DEBUG
        let testURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("v1_test.sqlite")
        try? MigrationTestHelper.createV1TestDatabase(at: testURL)
        print("Test DB created at: \\(testURL.path)")
        #endif
        
        Then use Xcode's device manager to inspect the file.
        
        ═══════════════════════════════════════════════════════════
        
        """
        
        print(instructions)
    }
}

// MARK: - Usage Example

/*
 
 // In your app or test code:
 
 import Foundation
 
 // Create a V1 test database
 let testURL = FileManager.default.temporaryDirectory
     .appendingPathComponent("migration_test.sqlite")
 
 try MigrationTestHelper.createV1TestDatabase(at: testURL)
 
 // Now you can copy this database to your app's container
 // and test the migration
 
 */
