//
//  HabitView.swift
//  Practice
//
//  Created by Robert Farley on 19/12/2025.
//

import SwiftUI

struct HabitView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(NavigationCoordinator.self) private var coordinator
    
    @Bindable var habit : Habit
    
    @State private var deleteAlertShowing : Bool = false
    
    var body: some View {
        
        VStack {
            VStack(spacing: 30) {
                
                HStack {
                    
                    Text(habit.name)
                        .font(.title)
                        .padding(.leading, 2)
                        .padding(.top, 5)
                    
                    Spacer()
                }
                
                HorizontalGitHubView(habit: habit, width: .wide)
                
                MonthView(selectedDate: Date(), habit: habit)
                
                Button(role: .destructive) {
                    
                    deleteAlertShowing = true
                    
                } label: {
                    Text("Delete Habit")
                        .padding(5)
                }
                .buttonStyle(.borderedProminent)
                
            }
            
            // padding internal to background, but also pushes card wider to make space
            .padding(.leading, 10)
            .padding(.vertical, 30)
            
            .background(Color.card)
            .cornerRadius(25)
            .frame(maxWidth: 600)
            // padding external to background
            .padding(.horizontal, 10)
            
            
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity)
        .background(Color.background)
        
        .alert("Delete Habit?", isPresented: $deleteAlertShowing) {
            Button("Delete", role: .destructive) {
                // navigate back out of HabitView
                coordinator.path.removeLast()
                
                // delete habit
                context.delete(habit)
                
                // save
                try? context.save()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    HabitView(
        habit: Habit.sampleData.first!
    )
    .environmentObject(ViewModel())
    .modelContainer(for: Habit.self)
    .environment(NavigationCoordinator())
}
