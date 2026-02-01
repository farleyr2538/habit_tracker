//
//  HabitCard.swift
//  Habit Tracker
//
//  Created by Rob Farley on 05/01/2026.
//

import SwiftUI

struct HabitCard : View {
    
    @Bindable var habit : Habit
    
    @State var tickIsHighlighted : Bool = false
    
    let today = calendar.startOfDay(for: Date())
    
    var body : some View {
        
        let color : Color = {
            if let colorHash = habit.colorHash {
                return Color(hex: colorHash)
            } else {
                return Color.green
            }
        }()
        
        VStack {
                                                        
            HStack {
                Text(habit.name)
                    .font(.title2)
                    .layoutPriority(1.0)
                
                Spacer()
                    .layoutPriority(0)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundStyle(tickIsHighlighted ? color : .gray.opacity(0.2))
                    Image(systemName: "checkmark")
                        .foregroundStyle(tickIsHighlighted ? .white : .unselectedCheckmark)
                        
                }
                .frame(width: 50, height: 50)
                .layoutPriority(1.0)
                
                .onTapGesture {
                    
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    if habit.dates.contains(today) {
                        habit.dates.removeAll(where: { $0 == today })
                        tickIsHighlighted = false
                    } else {
                        habit.dates.append(today)
                        tickIsHighlighted = true
                    }
                }
                
                
            } // end of HStack
            .padding(.top, 5)
            
            StaticHorizontalGitHubView(habit: habit)
                .layoutPriority(0)
            
        } // end of each habit view
        .onAppear {
            if habit.dates.contains(today) {
                tickIsHighlighted = true
            }
        }
        // internal padding
        .padding(.top, 10)
        .padding(.bottom, 10)
        .padding(.horizontal, 15)
        .background(Color.card)
        .cornerRadius(15)
        .frame(maxWidth: 400)
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
