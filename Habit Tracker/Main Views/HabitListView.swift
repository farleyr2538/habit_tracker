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
        
    func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            let habit = habits[index]
            context.delete(habit)
        }
        do {
            try context.save()
        } catch {
            print("unable to save following habit deletion")
        }
    }
    
    var columns = [
        GridItem(.adaptive(minimum: 400, maximum: 400), spacing: 10)
    ]
    
    var body: some View {
                    
        ScrollView {
            
            LazyVGrid(columns: columns) {
                
                ForEach(habits) { habit in
                    
                    HabitCard(habit: habit)
                    //.padding(.top, 10)
                        .padding(.horizontal, 15)
                        .onTapGesture {
                            coordinator.path.append(habit)
                        }
                        /*
                         not working
                         .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation {
                                    context.delete(habit)
                                    try? context.save()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                         */
                }
                .padding(.bottom, 10)
                
                
            }
            
            NavigationLink {
                // VerticalAllHabitsGrid()
                
                 if subscriptionManager.isPremium {
                    VerticalAllHabitsGrid()
                } else {
                    PaywallSheet()
                }
                
            } label: {
                Text("See All Habits")
                    .padding(10)
            }
            .buttonStyle(.bordered)
            .padding(.vertical)
        }
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
        .padding(.top, 1)
        .sheet(isPresented: $newHabitSheetShowing) {
            CreateHabitSheet(habitEditorShowing: $newHabitSheetShowing)
        }
        .sheet(isPresented: $paywallSheetShowing) {
            PaywallSheet()
        }
        .navigationTitle("My Habits")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.background, ignoresSafeAreaEdges: .all)
        
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
        .environmentObject(ViewModel())
        .environment(NavigationCoordinator())
        .environment(SubscriptionManager())
}
