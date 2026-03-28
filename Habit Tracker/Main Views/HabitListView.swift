//
//  HabitListView.swift
//  Practice
//
//  Created by Robert Farley on 24/05/2025.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    // SwiftData
    @Query(sort: [SortDescriptor(\Habit.order, order: .forward)]) private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    @State var newHabitSheetShowing : Bool = false
    @State var paywallSheetShowing : Bool = false
    
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
                    HabitCard(habit: habit)
                        .listRowInsets(EdgeInsets(top: 7.5, leading: 15, bottom: 7.5, trailing: 15))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            coordinator.path.append(habit)
                        }
                }
                .onMove(perform: moveHabit)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity)
            .background(Color.background, ignoresSafeAreaEdges: .all)
            //.environment(\.editMode, .constant(.active)) // Always in edit mode for drag
            
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
}
