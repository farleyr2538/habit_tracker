//
//  HabitView.swift
//  Practice
//
//  Created by Robert Farley on 19/12/2025.
//

import SwiftUI

struct HabitView: View {
    
    @Bindable var habit : Habit
    
    var body: some View {
        
        VStack {
            VStack(spacing: 30) {
                
                HStack {
                    
                    Text(habit.name)
                        .font(.title)
                    
                    Spacer()
                }
                
                HorizontalGitHubView(habit: habit, width: .wide)
                
                MonthView(selectedDate: Date(), habit: habit)
                
            }
            
            // padding internal to background, but also pushes card wider to make space
            .padding(.horizontal, 10)
            .padding(.vertical, 30)
            
            .background(Color.card)
            .cornerRadius(25)
            
            // padding external to background
            .padding(.horizontal)
            
            Spacer()
            
        }
        .background(Color.background)
    }
}

#Preview {
    HabitView(
        habit: Habit.sampleData.first!
    )
    .environmentObject(ViewModel())
}
