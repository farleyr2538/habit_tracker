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
    
    @State private var editSheetShowing : Bool = false
    
    @State private var hasJustDeleted : Bool = false
        
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
                
                MultiMonthView(habit: habit, color: .constant(nil))
                    .frame(height: 290)
                
                
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
        
        .toolbar {
            ToolbarItem {
                Button {
                    editSheetShowing = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        
        .sheet(isPresented: $editSheetShowing) {
            EditHabitSheet(habit: habit, hasJustDeleted: $hasJustDeleted)
        }
    }
}

#Preview {
    NavigationStack {
        HabitView(
            habit: Habit.sampleData.first!
        )
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self)
        .environment(NavigationCoordinator())
    }
}
