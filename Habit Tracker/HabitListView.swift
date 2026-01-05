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
    
    var columns = [
        GridItem(.adaptive(minimum: 400, maximum: 400), spacing: 10)
    ]
    
    var body: some View {
        
        let today = calendar.startOfDay(for: Date())
        
        //ScrollView {
            
            List {
                
                //LazyVGrid(columns: columns) {
                    
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
                                .onTapGesture {
                                    
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    
                                    if habit.dates.contains(today) {
                                        habit.dates.removeAll(where: { $0 == today })
                                    } else {
                                        habit.dates.append(today)
                                    }
                                }
                                .frame(width: 50, height: 50)
                                
                            }
                            //.padding(.top, 20)
                            .padding(.horizontal, 20)
                            
                            StaticHorizontalGitHubView(habit: habit)
                        }
                        
                        // .frame(width: 400)
                        .onTapGesture {
                            coordinator.path.append(habit)
                        }
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
                    }
                //}
            }
            // .listStyle(.plain)
        //}
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
