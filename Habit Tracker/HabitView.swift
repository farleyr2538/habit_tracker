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
            
            HStack {
                
                Text(habit.name)
                    .font(.title)
                
                Spacer()
            }
            
            HorizontalGitHubView(habit: habit, width: .wide)
            
            MonthView(selectedDate: Date(), habit: habit)
            
            Spacer()
            
        }
        .padding()
        
    }
}

#Preview {
    HabitView(
        habit: Habit.sampleData.first!
    )
    .environmentObject(ViewModel())
}
