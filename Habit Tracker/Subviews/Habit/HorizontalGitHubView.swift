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
    
    @State var numberOfDays : Int = 52 * 7
    @State var numberOfRows = 7
    
    var width : Width
    
    @State var scrollPosition : Int?
    
    var body: some View {
        
        let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
        let selectedWeekdaysArray = Array(selectedWeekdays.enumerated())
        
        let gridRows : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows) // number of rows permitted
        
        let endDate = viewModel.getEndOfCurrentWeek()
        let startDate = calendar.date(byAdding: .day, value: (1 - numberOfDays), to: calendar.startOfDay(for: endDate))!
                
        VStack {
            HStack {
                
                VStack {
                    ForEach(selectedWeekdaysArray, id: \.offset) { index, day in
                        if allWeekdays.contains(day) {
                            Text(day)
                                .font(.system(size: 8.0))
                        } else {
                            Text(day)
                                .hidden()
                        }
                        
                    }
                }
                
                ScrollView([.horizontal]) {
                    
                    LazyHGrid(rows: gridRows) {
                        
                        ForEach(0..<numberOfDays, id: \.self) { dayNumber in
                            
                            // for each day, create date, assess whether its in habit.dates
                            // or, create (weeks * 7) dates, and iterate through them, checking if each is present in habit.dates
                            
                            // create date
                            let date = calendar.date(byAdding: .day, value: dayNumber, to: startDate)!
                            
                            // check whether habit.dates contains date
                            let isComplete = habit.dates.contains(date)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 2.0)
                                    .foregroundStyle(isComplete ? .green : .gray.opacity(0.15))
                                
                                /*
                                 Text(date.description)
                                 .foregroundStyle(.white)
                                 .font(.custom("helvetica", size: 2.0))
                                 */
                                
                            }
                            .frame(width: 10, height: 10)
                            //.padding(.vertical, -2)
                            .padding(.horizontal, -3)
                        }
                        
                    }
                    .frame(height: 90)
                    .padding(.horizontal)
                    .scrollTargetLayout()
                    //.frame(height: 200)
                }
                .frame(height: 100)
                .scrollIndicators(.visible)
                .defaultScrollAnchor(.trailing)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $scrollPosition)
                .onAppear {
                    scrollPosition = numberOfDays
                    if width == .narrow {
                        numberOfDays = (52 * 7 / 2) + 14
                    }
                }
            }
            
            // add day number picker, eg. last week, last month, last 3, 6, 12, 24 months
            
            ScrollView(.horizontal) {
                HStack {
                    if numberOfDays != (52 * 7) {
                        Button {
                            numberOfDays = (52 * 7)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button("day") {
                        numberOfDays = 1
                    }
                    Button("week") {
                        numberOfDays = 7
                    }
                    Button("month") {
                        numberOfDays = (7*4)
                    }
                    Button("quarter") {
                        numberOfDays = (7*13)
                    }
                    /*
                    Button("100 days") {
                        numberOfDays = 100
                    }
                     */
                    Button("year") {
                        numberOfDays = (7*52)
                    }
                    
                    let habitStartingDate = habit.startFrom
                    let today = Date()
                    let difference = calendar.dateComponents([.day], from: habitStartingDate, to: today)
                    if let days = difference.day {
                        Button("since start of habit") {
                            numberOfDays = days
                        }
                    }
                }
                .buttonStyle(.bordered)
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            
            
        }
        
        
        
    }
}

#Preview {
    let previewHabit : Habit = Habit.sampleData.first!
    
    HorizontalGitHubView(habit: previewHabit, width: .narrow)
        .environmentObject(ViewModel())
}
