//
//  SwiftUIView.swift
//  Practice
//
//  Created by Robert Farley on 18/05/2025.
//

import SwiftUI
import SwiftData

struct MonthView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    // @Query var habits : [Habit]
    
    @State var selectedDate : Date // a date to show the month around
    @Bindable var habit : Habit
    
    var body: some View {
        
        let gridColumns = Array(repeating: GridItem(.fixed(40.0), spacing: 0), count: 7)
        
        let daysInMonth : Int = viewModel.daysInMonth(date: selectedDate)
        let firstDay : Int = viewModel.firstDayOfMonth(date: selectedDate)
        let totalDays = daysInMonth + firstDay // including initial buffers
        
        // get date info for display
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        let monthText = viewModel.monthName(from: calendar.component(.month, from: selectedDate))
                
        let daysOfWeek = ["Mon", "Tues", "Weds", "Thur", "Fri", "Sat", "Sun"]
        
        VStack(spacing: 20) {
            
            Text(monthText + " " + String(year))
                .font(.headline)
            
            HStack {
                
                Spacer()
                
                Chevron(direction: .left)
                    .onTapGesture {
                        // decrement month by one
                        if let newSelectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                            selectedDate = newSelectedDate
                        }
                        
                    }
                
                LazyVGrid(columns: gridColumns, spacing: 4) {
                    
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10.0))
                    }
                    .padding(.bottom, 5)
                    
                    ForEach(0..<(totalDays), id: \.self) { index in
                        if (index >= firstDay) {
                            
                            // create date
                            let dayNumber = index - firstDay + 1
                            let components = DateComponents.init(year: year, month: month, day: dayNumber)
                            if let date = calendar.date(from: components) {
                                // if date is in dates...
                                let isInDates = habit.dates.contains(date)
                                DayView(
                                    habit: habit,
                                    date: date,
                                    completed: isInDates ? true : false,
                                )
                            }
                        } else {
                            Spacer()
                        }
                    }
                }
                .frame(width: 290)
                
                Chevron(direction: .right)
                    .onTapGesture {
                        // incredment month by 1                        
                        if let newSelectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                            selectedDate = newSelectedDate
                        }
                    }
                
                Spacer()
                
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    MonthView(
        selectedDate: Date(),
        habit: Habit(name: "Running", dates: [Date()])
    )
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true)
}
