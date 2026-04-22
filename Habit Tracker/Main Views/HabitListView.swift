//
//  HabitListView.swift
//  Practice
//
//  Created by Robert Farley on 24/05/2025.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    
    @Environment(ViewModel.self) private var viewModel
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(CloudKitSyncMonitor.self) private var cloudKitMonitor
    
    // SwiftData
    @Query(sort: [SortDescriptor(\Habit.order, order: .forward)]) private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    @State var settingsSheetShowing : Bool = false
    @State var newHabitSheetShowing : Bool = false
    @State var paywallSheetShowing : Bool = false
    
    @State private var editMode : Bool = false
    @State private var contentOffset: CGFloat = 0
    @Environment(\.editMode) private var environmentEditMode
    
    private func moveHabit(from source: IndexSet, to destination: Int) {
        var reorderedHabits = habits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Update the order property for all habits
        for (index, habit) in reorderedHabits.enumerated() {
            habit.order = index
        }
    }
    
    var body: some View {
        
            List {
                
                ForEach(habits) { habit in
                    HStack {
                        Spacer()
                        HabitCard(habit: habit)
                        Spacer()
                    }
                        .offset(x: contentOffset)
                        .listRowInsets(EdgeInsets(
                            top: 7.5,
                            leading: 15,
                            bottom: 7.5,
                            trailing: 15
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            coordinator.path.append(habit)
                        }
                }
                .onMove(perform: editMode == true ? moveHabit : nil)
            }
            
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            .background(Color.background, ignoresSafeAreaEdges: .all)
        
            .toolbar {
                ToolbarItemGroup {
                    
                    if !editMode {
                        Button {
                            editMode.toggle()
                        } label: {
                            
                            Image(systemName: "slider.horizontal.3")
                            
                        }
                        
                        Button {
                            settingsSheetShowing.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    } else {
                        if #available(iOS 26.0, *) {
                            Button(role: .confirm) {
                                editMode = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            // Fallback on earlier versions
                            Button {
                                editMode = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            .onChange(of: editMode) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    contentOffset = newValue == true ? -20 : 0
                    environmentEditMode?.wrappedValue = newValue ? .active : .inactive
                }
            }
            
            // add habit button
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                Button {
                    // check if habits are greater or equal to 3
                    if !subscriptionManager.isPremium && habits.count >= 3 {
                        paywallSheetShowing = true
                    } else {
                        newHabitSheetShowing = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(.accent)
                            .frame(width: 50, height: 50)
                        Image(systemName: "plus")
                            .scaleEffect(1.2)
                            .foregroundStyle(Color.white)
                            .padding(10)
                    }
                }
                .padding(.trailing, 40)
                .padding(.bottom, 30)
                .shadow(radius: 15, x: 0, y: 5)
            }
            
            // new habit sheet
            .sheet(isPresented: $newHabitSheetShowing) {
                CreateHabitSheet(habitEditorShowing: $newHabitSheetShowing)
            }
            
            // paywall sheet
            .sheet(isPresented: $paywallSheetShowing) {
                PaywallSheet_SubscriptionStoreView()
            }
        
            // settings sheet
            .sheet(isPresented: $settingsSheetShowing) {
                SettingsView()
                    .environment(subscriptionManager)
                    .environment(cloudKitMonitor)
                    .environment(viewModel)
                    .presentationBackground(.ultraThinMaterial)
            }
    }
}

#Preview {
    NavigationStack {
        HabitListView()
            .modelContainer(for: Habit.self, inMemory: true) { result in
                if case .success(let container) = result {
                    Habit.sampleData.forEach { habit in
                        container.mainContext.insert(habit)
                    }
                }
            }
    }
    .environment(ViewModel())
    .environment(NavigationCoordinator())
    .environment(SubscriptionManager())
    .environment(CloudKitSyncMonitor())
}
