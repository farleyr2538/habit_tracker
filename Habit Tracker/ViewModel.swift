//
//  Data.swift
//  Habit Tracker
//
//  Created by Robert Farley on 18/05/2025.
//

import Foundation
import SwiftData
import SwiftUI

var calendar = Calendar.current
var formatter = DateFormatter()

@Model
class Habit : Hashable {
    
    var name : String
    var dates : [Date]
    // var colour : Color?
    
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

struct UserConfig {
    var isFirstTime : Bool = true
    var setupDate : Date = Date()
    var daysSinceSetup : Int = 0
    var daysLastMonth : Int = 0
    var monthBeforeSetup : Date = Date()
}

class ViewModel : ObservableObject {
    
    @Published var habits : [Habit] = []
    @Published var userConfig = UserConfig()
    
    
    
    init() { // record the date the user first sets up the app
                
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: userConfig.setupDate) { // returns optional Date type for same day in previous month
            let desiredMonth = calendar.component(.month, from: lastMonth)
            let currentYear = calendar.component(.year, from: userConfig.setupDate)
                        
            // create a new date: 01 / desiredMonth / currentYear
            let newDate : DateComponents = DateComponents.init(year: currentYear, month: desiredMonth, day: 1)
            if let date = calendar.date(from: newDate) {
                userConfig.monthBeforeSetup = date
            }
        }
        userConfig.isFirstTime = false
        
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        calendar.firstWeekday = 2
    }
    
    // calculate the number of days in any given month
    func daysInMonth(date: Date) -> Int {
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let components = DateComponents(year: year, month: month)
        
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 0
        }
        
        return range.count
    }
    
    // get which weekday the first day of any given month falls upon
    func firstDayOfMonth(date: Date) -> Int {
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let adjustedDateComponents = DateComponents.init(year: year, month: month, day: 1)
        
        if let adjustedDate = calendar.date(from: adjustedDateComponents) { // first date of current month
            let weekday = calendar.component(.weekday, from: adjustedDate) // int weekday of current month (Sunday = 1)
            if weekday == 2 {
                return 7
            } else if weekday == 1 {
                    return 6
            } else {
                return weekday - 2
            }
        } else {
            return -1
        }
    }
    
    func monthName(from monthNumber: Int) -> String {
        formatter.locale = Locale.current
        if let months = formatter.monthSymbols {
            guard monthNumber >= 1 && monthNumber <= 12 else {
                return "unknown month"
            }

            return months[monthNumber - 1]
        } else {
            return "Unknown month"
        }
    }
    
    func adjust(givenDate: Date, months: Int) -> Date {
        guard let newDate : Date = calendar.date(byAdding: .month, value: months, to: givenDate) else {
                fatalError("Could not create date")
        }
        return newDate
    }

    
    func datesInLast(dateComponent: Calendar.Component, number: Int) -> [Date] {
        var returnArray : [Date] = []
        let today = calendar.startOfDay(for: Date())
        let oneYearAgo = calendar.date(byAdding: dateComponent, value: (0 - number), to: today)
        
        if var index = oneYearAgo {
            while index <= today {
                returnArray.append(index)
                index = calendar.date(byAdding: .day, value: 1, to: index)!
            }
        }
        
        return returnArray
        
    }
}
