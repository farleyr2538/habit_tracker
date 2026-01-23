//
//  VerticalAllHabitsGrid.swift
//  Habit Tracker
//
//  Created by Rob Farley on 20/01/2026.
//

import SwiftUI
import SwiftData

struct VerticalAllHabitsGrid: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Query var habits : [Habit]
    
    @State var opacities : [Double] = []
    @Environment(\.modelContext) var context
    
    @State var infoSheetShowing : Bool = false
    
    @State var numberOfDays : Int = 52 * 7
    @State var numberOfCols : Int = 7
    
    @State var scrollPosition : Int?
    
    let boxDimensions : Double = 15.0
    
    var body: some View {
        
        let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
        let selectedWeekdaysArray = Array(selectedWeekdays.enumerated())
        
        let gridCols : [GridItem] = Array(repeating: GridItem(.fixed(boxDimensions), spacing: 5.0), count: numberOfCols) // number of rows permitted
                        
        VStack {
            
            /*
            
            // DEBUGGING
            
            VStack {
                // opacities debugging
                Text("number of habits: " + String(habits.count))
                
                Text("opacities length: " + String(opacities.count))
                
                if let firstOpacity = opacities.first {
                    Text("first opacity: " + String(firstOpacity))
                }
                
                if let maxOpacity = opacities.max() {
                    Text("highest opacity: " + String(maxOpacity))
                }
                
                // habits debugging
                HStack {
                    ForEach(habits, id: \.persistentModelID) { firstHabit in
                        VStack {
                            Text("habit name: " + firstHabit.name)
                            Text("dateCreated: " + firstHabit.dateCreated.formatted(date: .abbreviated, time: .shortened))
                            let startFrom = firstHabit.startFrom
                            Text("startFrom: " + startFrom.formatted(date: .abbreviated, time: .shortened))
                            
                            ForEach(firstHabit.dates, id: \.self) { date in
                                Text(String(date.formatted(date: .abbreviated, time: .shortened)))
                            }
                        }
                    }
                }
                .padding(.top)
                
            }
            .font(.system(size: 12.0))
             */
            
            VStack {
                
                HStack {
                    ForEach(selectedWeekdaysArray, id: \.offset) { index, day in
                        if allWeekdays.contains(day) {
                            Text(day)
                        } else {
                            Text(day)
                        }
                        
                    }
                }
                .font(.system(size: 10.0))
                
                ScrollView([.vertical]) {
                    
                    LazyVGrid(columns: gridCols) {
                        
                        ForEach(0..<opacities.count, id: \.self) { dayNumber in
                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 2.0)
                                    .foregroundStyle(opacities[dayNumber] == 0 ? Color.gray.opacity(0.1) : Color.green.opacity(opacities[dayNumber]))

                            }
                            .frame(width: boxDimensions, height: boxDimensions)
                            .padding(.vertical, -2)
                        }
                        
                    }
                    
                    .scrollTargetLayout()
                }
                .scrollIndicators(.visible)
                .defaultScrollAnchor(.bottom)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $scrollPosition)
                .onAppear {
                    scrollPosition = numberOfDays
                }
            }
            
            // add day number picker, eg. last week, last month, last 3, 6, 12, 24 months
            /*
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
            */
            
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
    VerticalAllHabitsGrid()
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true) { result in
                if case .success(let container) = result {
                    Habit.sampleData.forEach { habit in
                        container.mainContext.insert(habit)
                    }
            }
        }
}
