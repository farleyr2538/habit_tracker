//
//  GitHubView.swift
//  Practice
//
//  Created by Robert Farley on 26/05/2025.
//

import SwiftUI

struct VerticalGitHubView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var habit : Habit
    
    @State var numberOfDays : Int = 52 * 7
    @State var numberOfCols = 7
        
    @State var scrollPosition : Int?
    
    let boxDimensions = 15.0
    
    var body: some View {
        
        let allWeekdays = ["Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "", "Wed", "", "Fri", "", "Sun"]
        let selectedWeekdaysArray = Array(selectedWeekdays.enumerated())
        
        let gridCols : [GridItem] = Array(repeating: GridItem(.fixed(boxDimensions), spacing: 5.0), count: numberOfCols) // number of cols permitted
        
        let endDate = viewModel.getEndOfCurrentWeek()
        let startDate = calendar.date(byAdding: .day, value: (1 - numberOfDays), to: calendar.startOfDay(for: endDate))!
        
        let color : Color = {
            if let colorHash = habit.colorHash {
                return Color(hex: colorHash)
            } else {
                return Color.green
            }
        }()
                
        VStack {
            
            HStack {
                ForEach(selectedWeekdaysArray, id: \.offset) { index, day in
                    if allWeekdays.contains(day) {
                        Text(day)
                            
                    } else {
                        Text(day)
                            .hidden()
                    }
                    
                }
            }
            .font(.system(size: 12.0))
            
            ScrollView {
                
                LazyVGrid(columns: gridCols) {
                    
                    ForEach(0..<numberOfDays, id: \.self) { dayNumber in
                        
                        // for each day, create date, assess whether its in habit.dates
                        // or, create (weeks * 7) dates, and iterate through them, checking if each is present in habit.dates
                        
                        // create date
                        let date = calendar.date(byAdding: .day, value: dayNumber, to: startDate)!
                        
                        // check whether habit.dates contains date
                        let isComplete = habit.dates.contains(date)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 2.0)
                                .foregroundStyle(isComplete ? color : .gray.opacity(0.15))
                        }
                        .frame(width: boxDimensions, height: boxDimensions)
                        .padding(.vertical, -2)
                        // .padding(.horizontal, 3)
                    }
                    
                }
                //.frame(height: 90)
                .padding(.horizontal)
                //.scrollTargetLayout()
                //.frame(height: 200)
            }
            //.frame(width: 100)
            .scrollIndicators(.visible)
            
            /* SCROLL BEHAVIOUR */
            .defaultScrollAnchor(.bottom)
            .scrollBounceBehavior(.basedOnSize)
            .scrollPosition(id: $scrollPosition)
            .onAppear {
                scrollPosition = numberOfDays
            }
             
            
            /*
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
            */
            
        }
        
        
        
    }
}

#Preview {
    VerticalGitHubView(habit: Habit.sampleData.first!)
        .environmentObject(ViewModel())
}
