//
//  ContentView.swift
//  Habit Tracker
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    // Using @Environment instead of @EnvironmentObject for consistency
    // This prevents crashes when environment isn't properly set up
    @Environment(ViewModel.self) private var viewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(CloudKitSyncMonitor.self) private var cloudKitMonitor
    
    @State private var coordinator = NavigationCoordinator()
    
    @State var createHabitSheetShowing : Bool = false
    @State var newHabitError : Bool = false
    @State var settingsSheetShowing: Bool = false
    
    // SwiftData
    @Query private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        
        Group {
            if !habits.isEmpty {
                
                // TabView {
                    
                    // Tab("Habits", systemImage: "list.bullet") {
                        NavigationStack(path: $coordinator.path) {
                            HabitListView()
                                .navigationTitle("Habits")
                                .navigationDestination(for: Habit.self) { habit in
                                    HabitView(habit: habit)
                                }
                                .toolbar {
                                    ToolbarItem(placement: .primaryAction) {
                                        Button {
                                            settingsSheetShowing.toggle()
                                        } label: {
                                            Image(systemName: "gearshape")
                                        }
                                    }
                                }
                                .sheet(isPresented: $settingsSheetShowing) {
                                    SettingsView()
                                        .environment(subscriptionManager)
                                        .environment(cloudKitMonitor)
                                        .environment(viewModel)
                                        .presentationBackground(.ultraThinMaterial)
                                }
                        }
                        .environment(coordinator)
                    // }
                    
                /*
                    // Tab("Overview", systemImage: "chart.bar") {
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
                        .background(Color.background, ignoresSafeAreaEdges: .all)
                        .environment(coordinator)
                        .sheet(isPresented: $settingsSheetShowing) {
                            SettingsView()
                                .presentationBackground(.ultraThinMaterial)
                        }
                    //}
                    
                // }
                */
                
            } else {
                
                NavigationStack {
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
                    .navigationTitle("Habits")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                settingsSheetShowing.toggle()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
                .environment(coordinator)
                .sheet(isPresented: $createHabitSheetShowing) {
                    CreateHabitSheet(habitEditorShowing: $createHabitSheetShowing)
                        .presentationBackground(.ultraThinMaterial)
                }
                .sheet(isPresented: $settingsSheetShowing) {
                    SettingsView()
                        .environment(subscriptionManager)
                        .environment(cloudKitMonitor)
                        .environment(viewModel)
                        .presentationBackground(.ultraThinMaterial)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            // CloudKit Sync Indicator
            if cloudKitMonitor.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing to iCloud...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: cloudKitMonitor.isSyncing)

    }
}

#Preview {
    ContentView()
        .environment(SubscriptionManager())
        .environment(CloudKitSyncMonitor())
        .environment(NavigationCoordinator())
        .environment(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}


