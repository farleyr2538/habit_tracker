//
//  SingleMonthView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 22/01/2026.
//

import SwiftUI

struct SingleMonthView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Bindable var habit : Habit
    @State var selectedDate : Date // a date to show the month around
    
    let gridColumns = Array(repeating: GridItem(.fixed(40.0), spacing: 0), count: 7)
    
    let daysOfWeek = ["Mon", "Tues", "Weds", "Thur", "Fri", "Sat", "Sun"]
    
    var body: some View {
        
        let daysInMonth : Int = viewModel.daysInMonth(date: selectedDate)
        let firstDay : Int = viewModel.firstDayOfMonth(date: selectedDate)
        let totalDays = daysInMonth + firstDay // including initial buffers
        
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        
        let monthText = viewModel.monthName(from: calendar.component(.month, from: selectedDate))
        
        VStack {
            
            Text(monthText + " " + String(year))
                .font(.headline)
            
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
        }
    }
}

#Preview {
    SingleMonthView(
        habit: Habit.sampleData.first!,
        selectedDate: Date()
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
