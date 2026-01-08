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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                
        }
        .environmentObject(viewModel)
        .modelContainer(for: Habit.self)
    }
}
