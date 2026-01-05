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
    var dateCreated : Date = Date()
    var startFrom : Date?
    
    init(name: String, dates: [Date]) {
        self.name = name
        self.dates = dates
    }
}

extension Habit {
    
    static var sampleData: [Habit] {
        
        // dates should be 12, 14, 15 and 16 of December 2025
        
        let days = [12, 14, 15, 16]
        var components : [DateComponents] = []
        
        for day in days {
            components.append(DateComponents(year: 2025, month: 12, day: day))
        }
        
        var dates : [Date] = []
        for component in components {
            dates.append(calendar.date(from: component)!)
        }
        
        return [
            Habit(name: "Running", dates: dates),
            Habit(name: "Cooking", dates: dates)
        ]
    }
}
