//
//  ContentView.swift
//  Practice
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State private var coordinator = NavigationCoordinator()
    
    @State var habitEditorShowing : Bool = false
    @State var newHabitError : Bool = false
    
    // SwiftData
    @Query private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Group {
                if !habits.isEmpty {
                    HabitListView()
                        .navigationDestination(for: Habit.self) { habit in
                            HabitView(habit: habit)
                        }
                } else {
                    VStack {
                        Spacer()
                        
                        Text("No habits yet")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                            .padding()
                        
                        Spacer()
                        
                        NewHabitButton(habitEditorShowing: $habitEditorShowing)
                            .padding(.bottom)
                    }
                    
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                if !habits.isEmpty {
                    ToolbarItem {
                        Button {
                            habitEditorShowing = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
            }
        }
        .sheet(isPresented: $habitEditorShowing) {
            CreateHabitSheet(habitEditorShowing: $habitEditorShowing)
        }
        .environment(coordinator)
    }
}

#Preview {
    ContentView()
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}

