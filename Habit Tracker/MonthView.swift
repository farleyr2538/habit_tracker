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
    
    @State var selectedDate : Date = Date() // a date to show the month around
    @Bindable var habit : Habit
    
    var body: some View {
        
        let gridColumns = Array(repeating: GridItem(.flexible()), count: 7)
        
        let daysInMonth : Int = viewModel.daysInMonth(date: selectedDate)
        let firstDay : Int = viewModel.firstDayOfMonth(date: selectedDate)
        let totalDays = daysInMonth + firstDay
        
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        let monthText = viewModel.monthName(from: calendar.component(.month, from: selectedDate))
                
        let daysOfWeek = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        
        VStack {
            Text(monthText + " " + String(year))
                .font(.headline)
            HStack {
                Image(systemName: "chevron.left")
                    .onTapGesture {
                        // decrement month by one
                        selectedDate = viewModel.adjust(givenDate: selectedDate, months: -1)
                    }
                    .frame(width: 10, height: 10)
                LazyVGrid(columns: gridColumns) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.footnote)
                    }
                    ForEach(0..<(totalDays), id: \.self) { index in
                        if (index >= firstDay) {
                            let dayNumber = index - firstDay + 1
                            let components = DateComponents.init(year: year, month: month, day: dayNumber)
                            
                            if let updatedDate = calendar.date(from: components) {
                                // if date is in dates...
                                let isInDates = habit.dates.contains(where: {
                                    calendar.isDate($0, equalTo: updatedDate, toGranularity: .day)
                                })
                                DayView(completed: isInDates ? true : false, dates: $habit.dates, date: updatedDate)
                            }
                        } else {
                            Spacer()
                        }
                    }
                }
                .frame(minWidth: 300)
                .padding(.horizontal)
                
                Image(systemName: "chevron.right")
                    .onTapGesture {
                        // incredment month by 1
                        selectedDate = viewModel.adjust(givenDate: selectedDate, months: 1)
                    }
                
            }
            .padding(.bottom)
            /*
             ForEach(habit.dates, id: \.self) { date in
                Text(formatter.string(from: date))
            }
            */
            Spacer()
        }
        .padding(.vertical, 20)
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
