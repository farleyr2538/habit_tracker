//
//  HabitTracker.swift
//  Habit Tracker
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

@main
struct HabitTrackerApp : App {
    
    @StateObject var viewModel = ViewModel()
    
    @State private var subscriptionManager = SubscriptionManager()
    
    let container : ModelContainer
    
    init() {
        // initialize modelContainer

        let schema = Schema([
            Habit.self
        ])

        // Use shared app group container so widget can access the same data
        let appGroupID = "group.com.rob.habittracker"
        let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
        let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )

        let migrationPlan = MigrationPlan.self

        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(subscriptionManager)
        }
        .environmentObject(viewModel)
        .modelContainer(container)
    }
}
