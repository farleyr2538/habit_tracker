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
    
    // function to create an array of "opacities", reflecting what proportion of habits (that had started on this day) were completed. eg. 1.0 = all habits completed. 0.33 = 1/3 habits completed.
    func createDayScores(habits: [Habit]) -> [Double] {
        
        print("running createDayScores...")
        
        // let today = calendar.startOfDay(for: Date())
        let endOfThisWeek = getEndOfCurrentWeek()
        
        var opacities : [Double] = []
        
        let yearInWeeks = 7 * 52
        
        for x in 0..<yearInWeeks { // for each day in the last year
            
            // create date by subtracting x from today
            if let date = calendar.date(byAdding: .day, value: -x, to: endOfThisWeek) {
                
                print("\nNEW DATE: \(date.formatted(date: .abbreviated, time: .omitted))")

                var possibleHabits : Double = 0
                var completedHabits : Double = 0
                
                for habit in habits { // for each habit
                                        
                    let startingDate = habit.startFrom
                    if date >= startingDate { // if the date we are assessing is after the habit began, assess it
                        possibleHabits += 1 // acknowledge that this was an opportunity to complete the habit
                        if habit.dates.contains(date) { // if you completed this habit on this day
                            // print("incrementing completedHabits for habit: \(habit.name)")
                            completedHabits += 1 // increment completed habits
                            print("\(habit.name) completed")
                        }
                        
                    } // else, do not count this habit. proceed to the next.
                }
                
                print("possible habits: \(possibleHabits)")
                
                if possibleHabits != 0 { // if there were any habits created before this day
                    let preciseOpacityValue = (completedHabits / possibleHabits) // calculated the fraction of habits completed
                    let roundedOpacityValue = (preciseOpacityValue * 100).rounded() / 100 // round
                    opacities.insert(roundedOpacityValue, at: 0) // insert
                } else {
                    opacities.insert(0, at: 0) // no habits were created by this day -> opacity should equal 0
                }
                
                print("FINAL SCORE: \(completedHabits) / \(possibleHabits)")
                print("OPACITY: \(opacities[0])")
            } else {
                print("createDayScores() error: unable to create date equivalent to \(x) days ago")
                return [0]
            }
            
        }
        return opacities
    }
    
    // calculate correct startingDate for a given habit
    func calculateStartFrom(habit: Habit) -> Date {
        // return whichever is earlier of dateCreated or the first date in our habit
        
        let dateCreated = habit.dateCreated
        
        if let earliestDate = habit.dates.min() {
            if earliestDate < dateCreated {
                return earliestDate
            }
        }
        return dateCreated
    }
    
}


