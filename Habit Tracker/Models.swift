//
//  Models.swift
//  Practice
//
//  Created by Robert Farley on 22/12/2025.
//

import Foundation
import SwiftUI
import SwiftData

enum Width {
    case wide
    case narrow
}

struct viewOption {
    var text : String
    var days : Int
}

enum Direction {
    case left
    case right
}

typealias Habit = SchemaV3.Habit

enum SchemaV3 : VersionedSchema {
    
    static var versionIdentifier: Schema.Version {
        Schema.Version(3, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] { [SchemaV3.Habit.self] }
    
    @Model
    class Habit {
        
        var name : String = ""  // CloudKit requires default value
        var dates : [Date] = []  // CloudKit requires default value
        
        var colorHash : String?
        
        var dateCreated : Date = Date()  // CloudKit requires default value
        var startFrom : Date = Date()  // CloudKit requires default value
        var order : Int = 0  // Already has default value
        
        init(name: String, dates: [Date], colorHash: String? = nil, dateCreated: Date = Calendar.current.startOfDay(for: Date()), startFrom: Date = Calendar.current.startOfDay(for: Date()), order: Int = 0) {
            self.name = name
            self.dates = dates
            
            self.colorHash = colorHash
            
            self.dateCreated = dateCreated // the day the habit was created
            self.startFrom = startFrom // either the day the habit was created or the earliest date in its dates, whichever is earlier
            self.order = order
        }
    }
    
}

enum SchemaV2 : VersionedSchema {
    
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] { [SchemaV2.Habit.self] }
    
    @Model
    class Habit {
        
        var name : String
        var dates : [Date]
        
        var colorHash : String?
        
        var dateCreated : Date
        var startFrom : Date
        
        init(name: String, dates: [Date], colorHash: String? = nil, dateCreated: Date = Calendar.current.startOfDay(for: Date()), startFrom: Date = Calendar.current.startOfDay(for: Date())) {
            self.name = name
            self.dates = dates
            
            self.colorHash = colorHash
            
            self.dateCreated = dateCreated // the day the habit was created
            self.startFrom = startFrom // either the day the habit was created or the earliest date in its dates, whichever is earlier
        }
    }
    
}

enum SchemaV1 : VersionedSchema {
    
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] { [SchemaV1.Habit.self] }
    
    @Model
    class Habit : Hashable {
        
        var name : String
        var dates : [Date]
        
        var colorHash : String?
        
        var dateCreated : Date
        var startFrom : Date?
        
        init(name: String, dates: [Date], colorHash: String? = nil, dateCreated: Date = Calendar.current.startOfDay(for: Date()), startFrom: Date? = nil) {
            self.name = name
            self.dates = dates
            
            self.colorHash = colorHash
            
            self.dateCreated = dateCreated // the day the habit was created
            self.startFrom = startFrom // either the day the habit was created or the earliest date in dates, whichever is earlier
        }
    }
    
}


enum MigrationPlan : SchemaMigrationPlan {
    
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    
    static var stages: [MigrationStage] {
        [
            migrateV1ToV2,
            migrateV2ToV3
        ]
    }
    
    static let migrateV1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let habits = try context.fetch(FetchDescriptor<SchemaV1.Habit>())
            
            print("✅ V1→V2 Migration: Found \(habits.count) habits to migrate")
            
            let calendar = Calendar.current
            
            for habit in habits {
                
                habit.dateCreated = calendar.startOfDay(for: habit.dateCreated) // dateCreated is not optional, so has a value. dateCreated was at one point just the exact time the habit was made. instead, it should be the start of that day.
                
                if habit.startFrom == nil { // startFrom is an optional, and in most cases nil. Assign dateCreated to startFrom by default. this can be adapted later.
                    let dateCreated = habit.dateCreated
                    
                    if let earliestDate = habit.dates.min() {
                        
                        if earliestDate < dateCreated {
                            habit.startFrom = earliestDate
                        } else {
                            habit.startFrom = dateCreated
                        }
                        
                    } else {
                        habit.startFrom = dateCreated
                    }
                }
            }
            
            try context.save()
            print("✅ V1→V2 Migration: Successfully migrated \(habits.count) habits")
        },
        didMigrate: nil
    )
    
    static let migrateV2ToV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            // First, fetch all V2 habits before the schema change
            let v2Habits = try context.fetch(FetchDescriptor<SchemaV2.Habit>())
            
            // Sort them by dateCreated to preserve existing order
            let sortedHabits = v2Habits.sorted { $0.dateCreated < $1.dateCreated }
            
            // Store the order mapping before migration
            var orderMapping: [(persistentModelID: PersistentIdentifier, order: Int)] = []
            for (index, habit) in sortedHabits.enumerated() {
                orderMapping.append((habit.persistentModelID, index))
            }
            
            // Save the mapping to apply after schema changes
            try context.save()
            
            print("✅ V2→V3 Migration: Prepared order for \(v2Habits.count) habits")
        },
        didMigrate: { context in
            // After the schema change, apply the order values
            let v3Habits = try context.fetch(FetchDescriptor<SchemaV3.Habit>())
            
            // Sort by dateCreated to maintain order
            let sortedHabits = v3Habits.sorted { $0.dateCreated < $1.dateCreated }
            
            for (index, habit) in sortedHabits.enumerated() {
                habit.order = index
            }
            
            try context.save()
            
            print("✅ V2→V3 Migration: Assigned order to \(v3Habits.count) habits")
        }
    )
}


extension SchemaV3.Habit {
    
    /// Calculates the current streak of consecutive days for this habit
    /// - Returns: The number of consecutive days including today or yesterday
    func currentStreakCount() -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Normalize all dates to start of day and sort in descending order
        let sortedDates = dates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard let mostRecentDate = sortedDates.first else { return 0 }
        
        // Check if the streak is current (today or yesterday)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        guard mostRecentDate == today || mostRecentDate == yesterday else {
            return 0 // Streak is broken
        }
        
        // Count consecutive days going backwards
        var streakCount = 0
        var expectedDate = mostRecentDate
        
        for date in sortedDates {
            if date == expectedDate {
                streakCount += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if date < expectedDate {
                // There's a gap in the dates
                break
            }
            // Skip duplicate dates by continuing to next iteration
        }
        
        return streakCount
    }
    
    static var sampleData : [Habit] {
        
        let calendar = Calendar.current
        
        let decDays = [3, 6, 9, 15, 18, 22, 25, 28]
        var decDates : [Date] = []
        
        let janDays = [1, 3, 5, 7, 10, 13, 16, 20, 23, 27, 29]
        var janDates : [Date] = []
        
        for day in decDays {
            let components = DateComponents(year: 2025, month: 12, day: day)
            if let date = calendar.date(from: components) {
                decDates.append(date)
            }
        }
        
        for day in janDays {
            let components = DateComponents(year: 2026, month: 1, day: day)
            if let date = calendar.date(from: components) {
                janDates.append(date)
            }
        }
        
        let decStartDateComponents = DateComponents(year: 2025, month: 12, day: 1)
        let decStartDate = calendar.date(from: decStartDateComponents)!
        
        let janStartDateComponenents = DateComponents(year: 2026, month: 1, day: 1)
        let janStartDate = calendar.date(from: janStartDateComponenents)!
        
        return [
            Habit(name: "Running", dates: decDates, dateCreated: decStartDate, startFrom: decStartDate),
            Habit(name: "Knitting", dates: janDates, dateCreated: janStartDate, startFrom: janStartDate)
        ]
    }
}
