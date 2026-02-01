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
    @Query(sort: [SortDescriptor(\Habit.dateCreated, order: .forward)]) private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    @State var newHabitSheetShowing : Bool = false
    @State var paywallSheetShowing : Bool = false
    
    var body: some View {
        
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(habits) { habit in
                        HabitCard(habit: habit)
                            .onTapGesture {
                                coordinator.path.append(habit)
                            }
                    }
                }
                .padding(.horizontal, 15)
            }
            .frame(maxWidth: .infinity)
            .background(Color.background, ignoresSafeAreaEdges: .all)
            
            // add habit button
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                Button {
                    newHabitSheetShowing = true
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
                PaywallSheet()
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
    .environmentObject(ViewModel())
    .environment(NavigationCoordinator())
    .environment(SubscriptionManager())
}
