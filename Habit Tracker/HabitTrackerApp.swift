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
        do {
            container = try ModelContainer(
                for: Habit.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            fatalError("unable to generate container: \(error)")
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
