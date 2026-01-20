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

class ViewModel : ObservableObject {
    
    // @Published var habits : [Habit] = []
    @Published var userConfig = UserConfig()
    
    // private let modelContext : ModelContext
    
    init(/*modelContext: ModelContext*/) {
                
        // self.modelContext = modelContext
        
        // record the date the user first sets up the app
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
    
    /*func adjust(givenDate: Date, months: Int) -> Date {
        guard let newDate : Date = calendar.date(byAdding: .month, value: months, to: givenDate) else {
                fatalError("Could not create date")
        }
        return newDate
    }*/

    
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
    
    func getEndOfCurrentWeek() -> Date {
        
        let today = Date()
        
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            let end = weekInterval.end
            let weekEnd = calendar.date(byAdding: .day, value: -1, to: end)!
            return weekEnd
        } else {
            return Date()
        }
        
    }
    
    // function to create a "meta-habit", with a score each day representing the proportion of your habits that you completed that day
    func createDayScores(habits: [Habit]) -> [Double] {
        
        print("running createDayScores...")
        
        let today = calendar.startOfDay(for: Date())
        
        var opacities : [Double] = []
        
        let yearInWeeks = 7 * 52
        
        for x in 0..<yearInWeeks { // for each day in the last year
            
            // create date by subtracting x from today
            let date = calendar.date(byAdding: .day, value: -x, to: today)!
            
            var possibleHabits : Double = 0
            var completedHabits : Double = 0
            
            for habit in habits { // for each habit
                let startingDate = habit.startFrom
                if date >= startingDate { // if the date we are assessing is after the habit began
                    possibleHabits += 1 // acknowledge that this was an opportunity to complete the habit
                    if habit.dates.contains(date) { // if you completed this habit on this day
                        //print("incrementing completedHabits for habit: \(habit.name)")
                        completedHabits += 1 // increment completed habits
                    }
                } else {
                    //print("date \(date.description) is before habit \(habit.name) started")
                }
                /*} else {
                    print("unable to unwrap startingDate for habit: \(habit.name)")
                }*/
            }
            
            if possibleHabits != 0 {
                let preciseOpacityValue = (completedHabits / possibleHabits)
                let roundedOpacityValue = (preciseOpacityValue * 100).rounded() / 100
                opacities.insert(roundedOpacityValue, at: 0)
            } else {
                opacities.insert(0, at: 0)
            }
            
            
        }
        return opacities
    }
    
    // calculate correct startingDate for a given habit
    func calculateStartFrom(habit: Habit) -> Date {
        // return whichever is earlier of dateCreated or the first date in our habit
        
        let dateCreated = habit.dateCreated
        
        if let earliestDate = habit.dates.min() {
            
            if dateCreated < earliestDate {
                return dateCreated
            } else if dateCreated > earliestDate {
                return earliestDate
            } else {
                return dateCreated
            }
        } else {
            return dateCreated
        }
        
        
        
        
    }
    
}

// Color extension generated by AI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
