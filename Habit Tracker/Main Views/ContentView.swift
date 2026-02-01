//
//  ContentView.swift
//  Habit Tracker
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    @State private var coordinator = NavigationCoordinator()
    
    @State var createHabitSheetShowing : Bool = false
    @State var newHabitError : Bool = false
    
    // SwiftData
    @Query private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        
        Group {
            if !habits.isEmpty {
                
                TabView {
                    
                    Tab("List", systemImage: "list.bullet") {
                        NavigationStack(path: $coordinator.path) {
                            HabitListView()
                                .navigationTitle("Habits")
                                .navigationDestination(for: Habit.self) { habit in
                                    HabitView(habit: habit)
                                }
                        }
                    }
                    
                    Tab("Stats", systemImage: "chart.bar") {
                        NavigationStack {
                            /*
                            List {
                                NavigationLink(destination: HabitCompletionBarChart()) {
                                    Text("Habit Completion Bar Chart")
                                }
                                NavigationLink(destination: VerticalAllHabitsGrid()) {
                                    Text("Vertical Habits view")
                                }

                            }
                            */
                            VerticalAllHabitsGrid()
                        }
                        
                    }
                    
                }
                .background(Color.background, ignoresSafeAreaEdges: .all)
                .environment(coordinator)
                
            } else {
                
                VStack {
                    
                    Spacer()
                    
                    Text("No habits yet")
                        .font(.title3)
                        .padding(.top, 100)
                        .foregroundStyle(.secondary)
                           
                    Spacer()
                    
                    Button {
                        createHabitSheetShowing.toggle()
                    } label: {
                        Text("Create my first Habit")
                            .padding(15)
                            
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 50)
                }
                .sheet(isPresented: $createHabitSheetShowing) {
                    CreateHabitSheet(habitEditorShowing: $createHabitSheetShowing)
                        .presentationBackground(.ultraThinMaterial)
                }
            }
        }
        .frame(maxWidth: .infinity)

    }
}

#Preview {
    ContentView()
        .environment(SubscriptionManager())
        .environment(NavigationCoordinator())
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}


