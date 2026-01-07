//
//  HabitCard.swift
//  Habit Tracker
//
//  Created by Rob Farley on 05/01/2026.
//

import SwiftUI

struct HabitCard : View {
    
    @Bindable var habit : Habit
    
    let today = calendar.startOfDay(for: Date())
    
    var body : some View {
        
        VStack {
                                                        
            HStack {
                Text(habit.name)
                // .foregroundStyle(.black)
                    .font(.title2)
                
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
                
                
            } // end of HStack
            .padding(.top, 5)
            
            StaticHorizontalGitHubView(habit: habit)
        } // end of each habit view
        
        // internal padding
        .padding(.top, 10)
        .padding(.bottom, 10)
        .padding(.horizontal, 15)
        .background(Color.card)
        .cornerRadius(15)
        
    }
    
}

#Preview {
    
    if let sampleHabit = Habit.sampleData.first {
        HabitCard(habit: sampleHabit)
            .environmentObject(ViewModel())
    } else {
        Text("Unable to unwrap first sample habit")
    }
    
    
}
