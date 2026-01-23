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

typealias Habit = SchemaV2.Habit

enum SchemaV2 : VersionedSchema {
    
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] { [Habit.self] }
    
    @Model
    class Habit {
        
        var name : String
        var dates : [Date]
        
        var colorHash : String?
        
        var dateCreated : Date
        var startFrom : Date
        
        init(name: String, dates: [Date], colorHash: String? = nil, dateCreated: Date = calendar.startOfDay(for: Date()), startFrom: Date = calendar.startOfDay(for: Date())) {
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
    
    static var models: [any PersistentModel.Type] { [Habit.self] }
    
    @Model
    class Habit : Hashable {
        
        var name : String
        var dates : [Date]
        
        var colorHash : String?
        
        var dateCreated : Date
        var startFrom : Date?
        
        init(name: String, dates: [Date], colorHash: String? = nil, dateCreated: Date = calendar.startOfDay(for: Date()), startFrom: Date? = nil) {
            self.name = name
            self.dates = dates
            
            self.colorHash = colorHash
            
            self.dateCreated = dateCreated // the day the habit was created
            self.startFrom = startFrom // either the day the habit was created or the earliest date in dates, whichever is earlier
        }
    }
    
}


enum MigrationPlan : SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    
    static var stages: [MigrationStage] {
        [
            migrateV1ToV2
        ]
    }
    
    static let migrateV1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let habits = try context.fetch(FetchDescriptor<SchemaV1.Habit>())
            
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
        },
        didMigrate: nil
    )
}


extension SchemaV2.Habit {
    static var sampleData : [Habit] {
        
        let decDays = [3, 6, 9, 15]
        var decDates : [Date] = []
        
        let janDays = [1, 3, 5, 7]
        var janDates : [Date] = []
        
        for day in janDays {
            let components = DateComponents(year: 2025, month: 12, day: day)
            if let date = calendar.date(from: components) {
                decDates.append(date)
            }
        }
        
        for day in decDays {
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
