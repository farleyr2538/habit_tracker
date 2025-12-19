//
//  HorizontalGitHubView.swift
//  Practice
//
//  Created by Robert Farley on 18/12/2025.
//

import SwiftUI

struct HorizontalGitHubView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var habit : Habit
    
    @State var numberOfDays : Int = 365
    @State var numberOfRows = 7
    
    var body: some View {
        
        let gridRows : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows) // number of rows permitted
        
        // get weekday, and adjust it to 1 = Monday, 2 = Tuesday, etc.
        let currentDay = {
            if calendar.component(.weekday, from: Date()) == 1 {
                return 7
            } else {
                return calendar.component(.weekday, from: Date()) - 1
            }
        }()
        
        let datesInLastYear = viewModel.datesInLastYear()
        
        let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
        
        VStack {
            
            Spacer()
            
            ScrollView([.horizontal]) {
                
                LazyHGrid(rows: gridRows) {
                    
                    ForEach(selectedWeekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 8.0))
                    }
                    
                    ForEach(datesInLastYear, id: \.self) { date in
                        
                        let isComplete = habit.dates.contains(date)
                        
                        ZStack {
                            Rectangle()
                                .foregroundStyle(isComplete ? .green : .gray.opacity(2.0))
                            /*
                             Text(String(index + 1))
                             .foregroundStyle(.white)
                             .font(.custom("helvetica", size: 5.0))
                             */
                        }
                        .frame(width: 10, height: 10)
                        .padding(.vertical, -3)
                        .padding(.horizontal, -3)
                    }
                }
                .padding(.horizontal)
                //.frame(height: 200)
            }
            .frame(height: 100)
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
            
            /*
            HStack {
                Button("Year") {
                    numberOfRows = 7
                    numberOfDays = 365
                }
                Button("Month") {
                    if let daysInMonthRange = calendar.range(of: .day, in: .month, for: Date()) {
                        numberOfRows = 7
                        numberOfDays = daysInMonthRange.count
                    }
                }
                Button("Week") {
                    numberOfRows = 7
                    numberOfDays = 7
                }
                Button("Day") {
                    numberOfRows = 1
                    numberOfDays = 1
                }
            }
            .buttonStyle(.bordered)
             */
            
            Spacer()
        }
    }
}

#Preview {
    let previewHabit : Habit = Habit.sampleData.first!
    
    HorizontalGitHubView(habit: previewHabit)
        .environmentObject(ViewModel())
}
