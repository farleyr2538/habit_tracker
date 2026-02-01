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
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
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
