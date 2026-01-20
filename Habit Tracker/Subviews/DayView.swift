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
    
    var dimensions = 35.0
    
    let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        
        let dayNumber = calendar.component(.day, from: date)
        
        ZStack {
            Rectangle()
                .frame(width: dimensions, height: dimensions)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .scaleEffect(pressEffect ? 0.4 : 1)
                .foregroundStyle(completed ? .green : .black)

            Text(String(dayNumber))
                .foregroundStyle(.white)
                .font(.system(size: 16))
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
        completed: true
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
