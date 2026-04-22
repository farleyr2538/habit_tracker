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

@Observable
class ViewModel {
    
    var userConfig = UserConfig()
        
    init() {
                        
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
                
        let endOfThisWeek = getEndOfCurrentWeek()
        
        var opacities : [Double] = []
        
        let yearInWeeks = 7 * 52
        
        for x in 0..<yearInWeeks { // for each day in the last year
            
            // create date by subtracting x from today
            if let dateRaw = calendar.date(byAdding: .day, value: -x, to: endOfThisWeek) {
                let date = calendar.startOfDay(for: dateRaw) // Normalize to start of day
                
                var possibleHabits : Double = 0
                var completedHabits : Double = 0
                
                for habit in habits { // for each habit
                                        
                    let startingDate = calendar.startOfDay(for: habit.startFrom)
                    if date >= startingDate { // if the date we are assessing is after the habit began, assess it
                        possibleHabits += 1 // acknowledge that this was an opportunity to complete the habit
                        
                        if habit.dates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) { // check if any of the habit's dates match this day
                            completedHabits += 1 // increment completed habits
                        }
                    } // else, do not count this habit. proceed to the next.
                }
                
                if possibleHabits != 0 { // if there were any habits created before this day
                    let preciseOpacityValue = (completedHabits / possibleHabits) // calculated the fraction of habits completed
                    let roundedOpacityValue = (preciseOpacityValue * 100).rounded() / 100 // round
                    opacities.insert(roundedOpacityValue, at: 0) // insert
                } else {
                    opacities.insert(0, at: 0) // no habits were created by this day -> opacity should equal 0
                }
            } else {
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
    
    // MARK: - CloudKit Sync Debug Helper
    
    /// Prints comprehensive debug information about all habits and their CloudKit sync status
    /// Call this from anywhere in your app to diagnose sync issues
    /// Example: viewModel.debugCloudKitSync(habits: habits, context: modelContext)
    func debugCloudKitSync(habits: [Habit], context: ModelContext) {
        print("\n" + String(repeating: "=", count: 70))
        print("☁️ CLOUDKIT SYNC STATUS DEBUG REPORT")
        print("Generated: \(formatter.string(from: Date()))")
        print(String(repeating: "=", count: 70))
        
        // MARK: Configuration Status
        let cloudSyncDisabled = UserDefaults.standard.bool(forKey: "cloudSyncDisabled")
        let cachedPremiumStatus = UserDefaults.standard.bool(forKey: "cachedPremiumStatus")
        let migrationComplete = UserDefaults.standard.bool(forKey: AppGroupMigration.migrationCompleteKey)
        
        print("\n📊 CLOUDKIT CONFIGURATION:")
        print("   Premium Status: \(cachedPremiumStatus ? "✅ Active" : "❌ Inactive")")
        print("   CloudKit Sync: \(cloudSyncDisabled ? "❌ Disabled by User" : "✅ Enabled")")
        print("   App Group Migration: \(migrationComplete ? "✅ Complete" : "⚠️ Not Complete")")
        print("   Total Habits in Database: \(habits.count)")
        
        if !cachedPremiumStatus {
            print("\n   ⚠️ WARNING: CloudKit sync requires an active premium subscription")
            print("   Currently only storing data locally on this device")
        }
        
        if habits.isEmpty {
            print("\n⚠️ NO HABITS FOUND IN THE DATABASE!")
            print("   This could indicate:")
            print("   • Fresh install with no data")
            print("   • Failed migration from old storage location")
            print("   • CloudKit hasn't synced down data yet")
            print(String(repeating: "=", count: 70) + "\n")
            return
        }
        
        // MARK: Storage Location Info
        print("\n💾 STORAGE LOCATION:")
        if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rob.habittracker") {
            let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")
            print("   Database Path: \(storeURL.path)")
            
            if FileManager.default.fileExists(atPath: storeURL.path) {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: storeURL.path),
                   let fileSize = attributes[.size] as? Int {
                    let bytesFormatter = ByteCountFormatter()
                    bytesFormatter.allowedUnits = [.useKB, .useMB]
                    bytesFormatter.countStyle = .file
                    print("   Database Size: \(bytesFormatter.string(fromByteCount: Int64(fileSize)))")
                }
                
                if let modificationDate = try? FileManager.default.attributesOfItem(atPath: storeURL.path)[.modificationDate] as? Date {
                    print("   Last Modified: \(formatter.string(from: modificationDate))")
                }
            }
        }
        
        // MARK: Individual Habit Details
        print("\n📝 HABITS IN DATABASE (\(habits.count) total):")
        print(String(repeating: "-", count: 70))
        
        let sortedHabits = habits.sorted { $0.order < $1.order }
        
        for (index, habit) in sortedHabits.enumerated() {
            print("\n[\(index + 1)] \(habit.name)")
            print("    UUID: \(habit.id)")
            print("    Order: \(habit.order)")
            print("    Created: \(formatter.string(from: habit.dateCreated))")
            print("    Start From: \(formatter.string(from: habit.startFrom))")
            
            if let colorHash = habit.colorHash {
                print("    Color: \(colorHash)")
            }
            
            print("    Completions: \(habit.dates.count)")
            
            if !habit.dates.isEmpty {
                let sortedDates = habit.dates.sorted()
                if let first = sortedDates.first, let last = sortedDates.last {
                    print("    First completion: \(formatter.string(from: first))")
                    print("    Last completion: \(formatter.string(from: last))")
                    
                    // Calculate days between first and last completion
                    let daysBetween = calendar.dateComponents([.day], from: first, to: last).day ?? 0
                    if daysBetween > 0 {
                        let completionRate = Double(habit.dates.count) / Double(daysBetween + 1) * 100
                        print("    Completion Rate: \(String(format: "%.1f%%", completionRate)) over \(daysBetween) days")
                    }
                }
            } else {
                let daysSinceCreation = calendar.dateComponents([.day], from: habit.dateCreated, to: Date()).day ?? 0
                if daysSinceCreation > 0 {
                    print("    ⚠️ No completions in \(daysSinceCreation) days since creation")
                }
            }
            
            // Check persistence status
            let persistentID = habit.persistentModelID
            print("    Persistent Model ID: \(persistentID)")
            
            // Check if model is registered in context
            if context.model(for: persistentID) != nil {
                print("    Status: ✅ Registered in ModelContext")
            } else {
                print("    Status: ⚠️ NOT registered in ModelContext (sync issue?)")
            }
        }
        
        print("\n" + String(repeating: "-", count: 70))
        
        // MARK: Summary Statistics
        let totalCompletions = habits.reduce(0) { $0 + $1.dates.count }
        let avgCompletions = habits.isEmpty ? 0 : Double(totalCompletions) / Double(habits.count)
        
        print("\n📈 SUMMARY STATISTICS:")
        print("   Total Habits: \(habits.count)")
        print("   Total Completions: \(totalCompletions)")
        print("   Average Completions per Habit: \(String(format: "%.1f", avgCompletions))")
        
        if let oldestHabit = habits.min(by: { $0.dateCreated < $1.dateCreated }) {
            print("   Oldest Habit: '\(oldestHabit.name)' created \(formatter.string(from: oldestHabit.dateCreated))")
        }
        
        if let newestHabit = habits.max(by: { $0.dateCreated < $1.dateCreated }) {
            print("   Newest Habit: '\(newestHabit.name)' created \(formatter.string(from: newestHabit.dateCreated))")
        }
        
        // Calculate active habits (completed in last 7 days)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let activeHabits = habits.filter { habit in
            habit.dates.contains { $0 >= sevenDaysAgo }
        }
        print("   Active Habits (completed in last 7 days): \(activeHabits.count)")
        
        // MARK: Potential Issues Detection
        print("\n🔍 POTENTIAL SYNC ISSUES:")
        var issuesFound = false
        
        // Check for duplicate habit names
        let habitNames = habits.map { $0.name }
        let duplicateNames = Set(habitNames.filter { name in
            habitNames.filter { $0 == name }.count > 1
        })
        
        if !duplicateNames.isEmpty {
            print("   ⚠️ Duplicate habit names detected:")
            for name in duplicateNames {
                let count = habitNames.filter { $0 == name }.count
                print("      • '\(name)' appears \(count) times")
            }
            print("   This could indicate sync conflicts from multiple devices")
            issuesFound = true
        }
        
        // Check for duplicate orders
        let orders = habits.map { $0.order }
        let duplicateOrders = Set(orders.filter { order in
            orders.filter { $0 == order }.count > 1
        })
        
        if !duplicateOrders.isEmpty {
            print("   ⚠️ Duplicate order values detected: \(duplicateOrders.sorted())")
            print("   This may cause display issues in the habit list")
            issuesFound = true
        }
        
        // Check for old habits with no completions
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let oldEmptyHabits = habits.filter { $0.dates.isEmpty && $0.dateCreated < oneWeekAgo }
        
        if !oldEmptyHabits.isEmpty {
            print("   ⚠️ \(oldEmptyHabits.count) habit(s) older than 1 week with no completions:")
            for habit in oldEmptyHabits.prefix(5) {
                let daysOld = calendar.dateComponents([.day], from: habit.dateCreated, to: Date()).day ?? 0
                print("      • '\(habit.name)' (\(daysOld) days old)")
            }
            if oldEmptyHabits.count > 5 {
                print("      ... and \(oldEmptyHabits.count - 5) more")
            }
            issuesFound = true
        }
        
        // Check for habits with invalid UUIDs (all zeros or duplicates)
        let habitIDs = habits.map { $0.id }
        if habitIDs.count != Set(habitIDs).count {
            print("   ⚠️ Duplicate UUIDs detected - this is a serious data integrity issue!")
            issuesFound = true
        }
        
        if !issuesFound {
            print("   ✅ No obvious issues detected")
        }
        
        // MARK: CloudKit Sync Recommendations
        print("\n💡 CLOUDKIT SYNC RECOMMENDATIONS:")
        
        if !cachedPremiumStatus {
            print("   1. Premium subscription required for CloudKit sync")
            print("   2. Purchase premium to enable automatic sync across devices")
            print("   3. Data is currently stored locally only")
        } else if cloudSyncDisabled {
            print("   1. CloudKit sync is disabled by user")
            print("   2. Go to Settings to enable iCloud sync")
            print("   3. Once enabled, data will sync to other devices")
        } else {
            print("   ✅ CloudKit is properly configured and should be syncing")
            print("\n   If habits are missing on other devices:")
            print("   • Verify same iCloud account on all devices")
            print("   • Check iCloud Drive is enabled in iOS Settings")
            print("   • Ensure stable internet connection")
            print("   • Wait 2-5 minutes for initial sync to complete")
            print("   • Force quit and reopen the app on both devices")
            print("   • Check iOS Settings > [Your Name] > iCloud > iCloud Drive")
            print("     and ensure this app has permission")
        }
        
        // Check for migration issues
        if !migrationComplete {
            print("\n   ⚠️ App Group migration not complete!")
            print("   • Check Settings > Storage Locations for old data")
            print("   • Use the merge tool if old habits are detected")
        }
        
        print("\n" + String(repeating: "=", count: 70))
        print("END OF CLOUDKIT SYNC DEBUG REPORT")
        print(String(repeating: "=", count: 70) + "\n")
    }
    
}


