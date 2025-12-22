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
        ScrollView {
            ForEach(habits) { habit in
                
                VStack {
                    HStack {
                        Text(habit.name)
                            .font(.title3)
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0)
                                .foregroundStyle(.gray.opacity(0.2))
                            Image(systemName: "checkmark")
                        }
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            habit.dates.append(Date())
                        }
                        
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    HorizontalGitHubView(habit: habit, width: .narrow)
                }
                .onTapGesture {
                    coordinator.path.append(habit)
                }
                
            }
            .onDelete(perform: deleteHabit)
            
        }
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
}
