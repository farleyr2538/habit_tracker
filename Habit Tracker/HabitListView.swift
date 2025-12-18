//
//  HabitListView.swift
//  Practice
//
//  Created by Robert Farley on 24/05/2025.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    
    // SwiftData
    @Query private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
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
    
    var body: some View {
        List {
            ForEach(habits) { habit in
                NavigationLink(habit.name) {
                    MonthView(selectedDate: Date(), habit: habit)
                        .navigationTitle(habit.name)
                }
            }
            .onDelete(perform: deleteHabit)
        }
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true)
}
