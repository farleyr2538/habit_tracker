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
    @State private var editAlertShowing : Bool = false
    
    @State private var newName : String = ""
    
    var body: some View {
        
        VStack {
            VStack(spacing: 30) {
                
                HStack {
                    
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.title)
                        
                        Text("Created: " + habit.dateCreated.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.leading, 10)
                    .padding(.top, 5)
                    
                    Spacer()
                }
                
                HorizontalGitHubView(habit: habit, width: .wide)
                
                MonthView(habit: habit)
                    .frame(height: 300)
                
                HStack(spacing: 20) {
                    
                    Button {
                        editAlertShowing = true
                    } label: {
                        Text("Rename Habit")
                            .padding(5)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(role: .destructive) {
                        
                        deleteAlertShowing = true
                        
                    } label: {
                        Text("Delete Habit")
                            .padding(5)
                    }
                    .buttonStyle(.borderedProminent)
                    
                }
                
                
            }
            
            // padding internal to background, but also pushes card wider to make space
            .padding(.horizontal, 10)
            .padding(.vertical, 30)
            
            .background(Color.card)
            .cornerRadius(25)
            .frame(maxWidth: 600) // for iPad
            
            // padding external to background
            .padding(.horizontal, 15)
            
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
        .alert("Rename Habit", isPresented: $editAlertShowing) {
            TextField("New Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                
                habit.name = newName
                newName = ""
                
                try? context.save()
            }
            .disabled(newName.isEmpty)
        } message: {
            Text("Please enter a new name")
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
