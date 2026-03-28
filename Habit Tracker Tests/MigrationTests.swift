//
//  MigrationTests.swift
//  Habit Tracker Tests
//
//  Test migration paths from V1 → V2 → V3
//

import Testing
import SwiftData
import Foundation
@testable import Habit_Tracker

@Suite("Migration Tests")
@MainActor
struct MigrationTests {
    
    // MARK: - Helper to create temporary store URL
    private func createTemporaryStoreURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).sqlite")
        return storeURL
    }
    
    // MARK: - Helper to cleanup store
    private func cleanup(storeURL: URL) {
        let storeDirectory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        let relatedFiles = [storeName, storeName + "-wal", storeName + "-shm"]
        
        for fileName in relatedFiles {
            let fileURL = storeDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Test V1 to V2 Migration
    @Test("V1 to V2 Migration")
    @MainActor
    func testV1ToV2Migration() async throws {
        let storeURL = createTemporaryStoreURL()
        
        // Step 1: Create a V1 container and add test data
        do {
            let v1Schema = Schema([SchemaV1.Habit.self])
            let v1Config = ModelConfiguration(
                schema: v1Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v1Container = try ModelContainer(
                for: v1Schema,
                configurations: [v1Config]
            )
            
            let context = v1Container.mainContext
            
            // Create test habits with nil startFrom (the V1 default for many users)
            let habit1 = SchemaV1.Habit(
                name: "Morning Run",
                dates: [],
                dateCreated: Date(timeIntervalSince1970: 1704067200), // Jan 1, 2024, 00:00:00
                startFrom: nil  // This is the problematic case
            )
            
            let habit2 = SchemaV1.Habit(
                name: "Read Books",
                dates: [Date(timeIntervalSince1970: 1704153600)], // Jan 2, 2024
                dateCreated: Date(timeIntervalSince1970: 1704240000), // Jan 3, 2024
                startFrom: nil  // This should get the earliest date (Jan 2)
            )
            
            context.insert(habit1)
            context.insert(habit2)
            try context.save()
            
            print("✅ Created V1 database with 2 habits")
        }
        
        // Step 2: Now open with V2 schema and migration plan
        do {
            let v2Schema = Schema([SchemaV2.Habit.self])
            let v2Config = ModelConfiguration(
                schema: v2Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            // Create migration plan with just V1→V2
            enum TestMigrationPlan: SchemaMigrationPlan {
                static var schemas: [any VersionedSchema.Type] = [
                    SchemaV1.self,
                    SchemaV2.self
                ]
                
                static var stages: [MigrationStage] {
                    [MigrationPlan.migrateV1ToV2]
                }
            }
            
            let v2Container = try ModelContainer(
                for: v2Schema,
                migrationPlan: TestMigrationPlan.self,
                configurations: [v2Config]
            )
            
            let context = v2Container.mainContext
            let descriptor = FetchDescriptor<SchemaV2.Habit>(
                sortBy: [SortDescriptor(\.dateCreated)]
            )
            let migratedHabits = try context.fetch(descriptor)
            
            print("✅ V2 Migration complete. Found \(migratedHabits.count) habits")
            
            // Verify the migration worked
            #expect(migratedHabits.count == 2, "Should have 2 migrated habits")
            
            let habit1 = migratedHabits[0]
            #expect(habit1.name == "Morning Run")
            #expect(habit1.startFrom == calendar.startOfDay(for: Date(timeIntervalSince1970: 1704067200)))
            
            let habit2 = migratedHabits[1]
            #expect(habit2.name == "Read Books")
            // Should have the earliest date (Jan 2) since it's before dateCreated (Jan 3)
            #expect(habit2.startFrom == Date(timeIntervalSince1970: 1704153600))
        }
        
        cleanup(storeURL: storeURL)
    }
    
    // MARK: - Test V2 to V3 Migration
    @Test("V2 to V3 Migration")
    @MainActor
    func testV2ToV3Migration() async throws {
        let storeURL = createTemporaryStoreURL()
        
        // Step 1: Create a V2 container with test data
        do {
            let v2Schema = Schema([SchemaV2.Habit.self])
            let v2Config = ModelConfiguration(
                schema: v2Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v2Container = try ModelContainer(
                for: v2Schema,
                configurations: [v2Config]
            )
            
            let context = v2Container.mainContext
            
            // Create habits with different creation dates (should determine order)
            let habit1 = SchemaV2.Habit(
                name: "First Habit",
                dates: [],
                dateCreated: Date(timeIntervalSince1970: 1704067200), // Jan 1, 2024
                startFrom: Date(timeIntervalSince1970: 1704067200)
            )
            
            let habit2 = SchemaV2.Habit(
                name: "Third Habit",
                dates: [],
                dateCreated: Date(timeIntervalSince1970: 1704240000), // Jan 3, 2024
                startFrom: Date(timeIntervalSince1970: 1704240000)
            )
            
            let habit3 = SchemaV2.Habit(
                name: "Second Habit",
                dates: [],
                dateCreated: Date(timeIntervalSince1970: 1704153600), // Jan 2, 2024
                startFrom: Date(timeIntervalSince1970: 1704153600)
            )
            
            // Insert in wrong order to test sorting
            context.insert(habit2)
            context.insert(habit1)
            context.insert(habit3)
            try context.save()
            
            print("✅ Created V2 database with 3 habits")
        }
        
        // Step 2: Migrate to V3
        do {
            let v3Schema = Schema([SchemaV3.Habit.self])
            let v3Config = ModelConfiguration(
                schema: v3Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            // Create migration plan with just V2→V3
            enum TestMigrationPlan: SchemaMigrationPlan {
                static var schemas: [any VersionedSchema.Type] = [
                    SchemaV2.self,
                    SchemaV3.self
                ]
                
                static var stages: [MigrationStage] {
                    [MigrationPlan.migrateV2ToV3]
                }
            }
            
            let v3Container = try ModelContainer(
                for: v3Schema,
                migrationPlan: TestMigrationPlan.self,
                configurations: [v3Config]
            )
            
            let context = v3Container.mainContext
            let descriptor = FetchDescriptor<SchemaV3.Habit>(
                sortBy: [SortDescriptor(\.order)]
            )
            let migratedHabits = try context.fetch(descriptor)
            
            print("✅ V3 Migration complete. Found \(migratedHabits.count) habits")
            
            // Verify migration worked and order is correct
            #expect(migratedHabits.count == 3, "Should have 3 migrated habits")
            
            // Habits should be ordered by dateCreated (which determines order value)
            #expect(migratedHabits[0].name == "First Habit")
            #expect(migratedHabits[0].order == 0)
            
            #expect(migratedHabits[1].name == "Second Habit")
            #expect(migratedHabits[1].order == 1)
            
            #expect(migratedHabits[2].name == "Third Habit")
            #expect(migratedHabits[2].order == 2)
            
            // Verify no duplicate orders
            let orders = Set(migratedHabits.map { $0.order })
            #expect(orders.count == 3, "All order values should be unique")
        }
        
        cleanup(storeURL: storeURL)
    }
    
    // MARK: - Test Full Migration Path
    @Test("Full Migration Path (V1 → V2 → V3)")
    @MainActor
    func testFullMigrationPath() async throws {
        let storeURL = createTemporaryStoreURL()
        
        // Step 1: Create V1 database
        do {
            let v1Schema = Schema([SchemaV1.Habit.self])
            let v1Config = ModelConfiguration(
                schema: v1Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v1Container = try ModelContainer(
                for: v1Schema,
                configurations: [v1Config]
            )
            
            let context = v1Container.mainContext
            
            // Create V1 habits with various edge cases
            let habit1 = SchemaV1.Habit(
                name: "Old Habit",
                dates: [
                    Date(timeIntervalSince1970: 1704067200),  // Jan 1
                    Date(timeIntervalSince1970: 1704153600)   // Jan 2
                ],
                dateCreated: Date(timeIntervalSince1970: 1704240000), // Jan 3
                startFrom: nil  // Should become Jan 1 (earliest date)
            )
            
            let habit2 = SchemaV1.Habit(
                name: "Newer Habit",
                dates: [],
                dateCreated: Date(timeIntervalSince1970: 1704326400), // Jan 4
                startFrom: nil  // Should become Jan 4 (dateCreated)
            )
            
            context.insert(habit1)
            context.insert(habit2)
            try context.save()
            
            print("✅ Created V1 database")
        }
        
        // Step 2: Migrate directly to V3 (tests the full migration path)
        do {
            let v3Schema = Schema([SchemaV3.Habit.self])
            let v3Config = ModelConfiguration(
                schema: v3Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v3Container = try ModelContainer(
                for: v3Schema,
                migrationPlan: MigrationPlan.self,  // Use the full migration plan
                configurations: [v3Config]
            )
            
            let context = v3Container.mainContext
            let descriptor = FetchDescriptor<SchemaV3.Habit>(
                sortBy: [SortDescriptor(\.order)]
            )
            let migratedHabits = try context.fetch(descriptor)
            
            print("✅ Full migration (V1→V2→V3) complete")
            
            // Verify all migrations worked
            #expect(migratedHabits.count == 2, "Should have 2 habits")
            
            // First habit (created on Jan 3)
            let habit1 = migratedHabits[0]
            #expect(habit1.name == "Old Habit")
            #expect(habit1.order == 0)
            #expect(habit1.startFrom == Date(timeIntervalSince1970: 1704067200)) // Jan 1
            
            // Second habit (created on Jan 4)
            let habit2 = migratedHabits[1]
            #expect(habit2.name == "Newer Habit")
            #expect(habit2.order == 1)
            #expect(habit2.startFrom == calendar.startOfDay(for: Date(timeIntervalSince1970: 1704326400))) // Jan 4
            
            print("✅ All verifications passed!")
        }
        
        cleanup(storeURL: storeURL)
    }
    
    // MARK: - Test Edge Case: Empty Database
    @Test("Empty Database Migration")
    @MainActor
    func testEmptyDatabaseMigration() async throws {
        let storeURL = createTemporaryStoreURL()
        
        // Create empty V1 database
        do {
            let v1Schema = Schema([SchemaV1.Habit.self])
            let v1Config = ModelConfiguration(
                schema: v1Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v1Container = try ModelContainer(
                for: v1Schema,
                configurations: [v1Config]
            )
            
            // Don't insert any data
            try v1Container.mainContext.save()
        }
        
        // Migrate to V3
        do {
            let v3Schema = Schema([SchemaV3.Habit.self])
            let v3Config = ModelConfiguration(
                schema: v3Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            
            let v3Container = try ModelContainer(
                for: v3Schema,
                migrationPlan: MigrationPlan.self,
                configurations: [v3Config]
            )
            
            let context = v3Container.mainContext
            let descriptor = FetchDescriptor<SchemaV3.Habit>()
            let habits = try context.fetch(descriptor)
            
            #expect(habits.isEmpty, "Empty database should remain empty after migration")
            
            print("✅ Empty database migration handled correctly")
        }
        
        cleanup(storeURL: storeURL)
    }
}
