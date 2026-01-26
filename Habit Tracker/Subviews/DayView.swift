//
//  DayView.swift
//  Practice
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI

struct DayView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Bindable var habit : Habit
    var date : Date
    
    @State var pressEffect : Bool = false
    var completed : Bool
    
    let impact = UIImpactFeedbackGenerator(style: .medium)
    
    @Binding var color : Color?
    @State var highlightColor : Color = .green
    
    var body: some View {
        
        let dayNumber = calendar.component(.day, from: date)
        
        ZStack {
            DayBox(dayNumber: dayNumber)
                .scaleEffect(pressEffect ? 0.4 : 1)
                .foregroundStyle(completed ? color ?? Color.init(hex: habit.colorHash ?? "34C759") : .black)
        }
        .onTapGesture {
            
            // haptic
            impact.impactOccurred()
            
            // apply scale effect
            withAnimation(.bouncy) {
                pressEffect = true
            }
            
            // create copies of required variables
            var startingFrom = habit.startFrom
            var dates = habit.dates
            
            if !completed {
                // add date to dates
                dates.append(calendar.startOfDay(for: date))
                
                // if date is before startingDate, set startingDate to this date
                if date < startingFrom {
                    startingFrom = date
                }
                
            } else {
                // remove date from dates
                dates.removeAll { calendar.isDate($0, inSameDayAs: date) }
                
                // if this was the earliest date (ie. before dateCreated and before any other date), set startingDate to the next earliest date
                
                // create a new startingFrom
                startingFrom = viewModel.calculateStartFrom(habit: habit)
            }
            
            // re-assign variables to habit
            habit.dates = dates
            habit.startFrom = startingFrom
            
            // disapply scale effect after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.bouncy) {
                    pressEffect = false
                }
            }
            
        }
    }
}

#Preview {
    DayView(
        habit: Habit.sampleData.first!,
        date: Calendar.current.startOfDay(for: Date()),
        completed: true,
        color: .constant(.yellow)
    )
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}
