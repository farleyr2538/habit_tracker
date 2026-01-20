//
//  AllHabitsGrid.swift
//  Habit Tracker
//
//  Created by Rob Farley on 15/01/2026.
//

import SwiftUI
import SwiftData

struct AllHabitsGrid: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Query var habits : [Habit]
    
    @State var opacities : [Double] = []
    @Environment(\.modelContext) var context
    
    @State var infoSheetShowing : Bool = false
    
    @State var numberOfDays : Int = 52 * 7
    @State var numberOfRows = 7
    
    @State var scrollPosition : Int?
    
    var body: some View {
        
        let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
        let selectedWeekdaysArray = Array(selectedWeekdays.enumerated())
        
        let gridRows : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows) // number of rows permitted
                        
        VStack {
            
            /*
             
             DEBUGGING
            
            // opacities debugging
            Text("opacities length: " + String(opacities.count))
            
            if let firstOpacity = opacities.first {
                Text("first opacity: " + String(firstOpacity))
            }
            
            if let maxOpacity = opacities.max() {
                Text("highest opacity: " + String(maxOpacity))
            }
            
            // habits debugging
            if let firstHabit = habits.first {
                Text("first habit name: " + firstHabit.name)
                Text("dateCreated: " + firstHabit.dateCreated.description)
                let startFrom = firstHabit.startFrom
                Text("startFrom: " + startFrom.description)
                /*} else {
                    Text("unable to unwrap startFrom")
                }*/
                ForEach(firstHabit.dates, id: \.self) { date in
                    Text(String(date.description))
                }
                
            } else {
                Text("unable to get first habit")
            }
            
            Text("number of habits: " + String(habits.count))
            
            */
            
            
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
                        
                        ForEach(0..<opacities.count, id: \.self) { dayNumber in
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 2.0)
                                    .foregroundStyle(opacities[dayNumber] == 0 ? Color.gray.opacity(0.1) : Color.green.opacity(opacities[dayNumber]))

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
                    
                }
                .buttonStyle(.bordered)
                .padding(.vertical)
            }
            .scrollIndicators(.hidden)
            
            
        }
        .onAppear {
            opacities = viewModel.createDayScores(habits: habits)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    infoSheetShowing = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $infoSheetShowing) {
            InfoSheet()
        }
        
    }
}


#Preview {    
    AllHabitsGrid()
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}
