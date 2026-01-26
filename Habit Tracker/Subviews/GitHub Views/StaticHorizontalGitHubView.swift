//
//  StaticHorizontalGitHubView.swift
//  Habit Tracker
//
//  Created by Robert Farley on 23/12/2025.
//

import SwiftUI

struct StaticHorizontalGitHubView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var habit : Habit
    
    @State var numberOfDays : Int = 26 * 7
    @State var numberOfRows = 7
    
    var body: some View {
        
        let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "Weds", "Fri", "Sun"]
        
        let gridRows : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows) // number of rows permitted
        
        let endDate = viewModel.getEndOfCurrentWeek()
        let startDate = calendar.date(byAdding: .day, value: (1 - numberOfDays), to: calendar.startOfDay(for: endDate))!
        
        let color : Color = {
            if let colorHash = habit.colorHash {
                return Color(hex: colorHash)
            } else {
                return Color.green
            }
        }()
        
        LazyHGrid(rows: gridRows) {
            
            ForEach(allWeekdays, id: \.self) { day in
                if selectedWeekdays.contains(day) {
                    Text(day)
                        .font(.system(size: 8.0))
                } else {
                    Spacer()
                }
            }
            
            ForEach(0..<numberOfDays, id: \.self) { dayNumber in
                
                // create date
                let date = calendar.date(byAdding: .day, value: dayNumber, to: startDate)!
                
                // check whether habit.dates contains date
                let isComplete = habit.dates.contains(date)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 2.0)
                        .foregroundStyle(isComplete ? color : .gray.opacity(0.15))
                    
                }
                .frame(width: 10, height: 10)
                //.padding(.vertical, -2)
                .padding(.horizontal, -3)
            }
        }
        .frame(height: 90)
        //.padding(.horizontal)
        .scrollTargetLayout()
    }
}

#Preview {
    let previewHabit : Habit = Habit.sampleData.first!
    
    StaticHorizontalGitHubView(habit: previewHabit)
        .environmentObject(ViewModel())
}
