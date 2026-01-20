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
                        .onAppear {
                            for habit in habits {
                                habit.startFrom = viewModel.calculateStartFrom(habit: habit)
                                
                                try? context.save() 
                            }
                        }
                        
                } else {
                    
                    VStack {
                        
                        Spacer()
                        
                        Text("No habits yet")
                            .font(.title3)
                            .padding(.top, 100)
                            .foregroundStyle(.secondary)
                               
                        Spacer()
                        
                        Button {
                            habitEditorShowing.toggle()
                        } label: {
                            Text("Create my first Habit")
                                .padding(15)
                                
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 50)
                                                
                        /*
                        Group {
                            
                            if #available(iOS 26.0, *) {
                                Button {
                                    habitEditorShowing.toggle()
                                } label: {
                                    Text("Create my first Habit")
                                        .padding(15)
                                        .foregroundStyle(.black.opacity(0.8))
                                }
                                .buttonStyle(.glass)
                                .glassEffect()
                                
                            } else {
                                
                                Button {
                                    habitEditorShowing.toggle()
                                } label: {
                                    Text("Create my first Habit")
                                        .padding(15)
                                }
                                .background(Capsule())
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.top, 250)
                        .padding(.bottom, 100)
                         */
                    }
                    .sheet(isPresented: $habitEditorShowing) {
                        CreateHabitSheet(habitEditorShowing: $habitEditorShowing)
                            .presentationBackground(.ultraThinMaterial)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.background)
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


