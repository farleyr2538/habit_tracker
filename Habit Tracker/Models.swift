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

@Model
class Habit : Hashable {
    
    var name : String
    var dates : [Date]
    var colorHash : String?
    var dateCreated : Date
    var startFrom : Date?
    
    init(name: String, dates: [Date], colorHash: String? = nil, startFrom: Date? = nil) {
        self.name = name
        self.dates = dates
        
        self.colorHash = colorHash
        
        self.dateCreated = Date()
        self.startFrom = startFrom
    }
}

extension Habit {
    
    static var sampleData: [Habit] {
        
        // dates should be 12, 14, 15 and 16 of December 2025
        
        let decemberDays = [12, 14, 15, 16]
        var decemberComponents : [DateComponents] = []
        
        for day in decemberDays {
            decemberComponents.append(DateComponents(year: 2025, month: 12, day: day))
        }
        
        var dates : [Date] = []
        for component in decemberComponents {
            dates.append(calendar.date(from: component)!)
        }
        
        let januaryDays = [3, 5, 6, 8]
        var januaryComponents : [DateComponents] = []
        
        for day in januaryDays {
            januaryComponents.append(DateComponents(year: 2025, month: 12, day: day))
        }
        
        for component in januaryComponents {
            dates.append(calendar.date(from: component)!)
        }
        
        return [
            Habit(name: "Running", dates: dates, startFrom: dates.first!),
            Habit(name: "Cooking", dates: dates, startFrom: dates.first!),
            Habit(name: "Reading the Bible", dates: dates, startFrom: dates.first!),
            Habit(name: "Waking up early", dates: dates, startFrom: dates.first!)
        ]
    }
}

struct viewOption {
    var text : String
    var days : Int
}

enum Direction {
    case left
    case right
}
