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
    
    @State var daysToShow : Int = 52 * 7
    @State var numberOfCols : Int = 7
    
    @State var scrollPosition : Int?
    
    @State var boxDimensions : Double = 15.0
    var textSize = 10.0
    
    let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
    let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
    
    var body: some View {
        
        let selectedWeekdaysArray = Array(selectedWeekdays.enumerated())
        
        let gridCols : [GridItem] = Array(repeating: GridItem(.fixed(boxDimensions), spacing: 5.0), count: numberOfCols) // number of rows permitted
                        
        VStack {
            
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
                .font(.system(size: textSize))
                
                
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
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.bottom)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $scrollPosition, anchor: .bottom)
                //.padding(.bottom, 50)
                
            }
            
            /*
            // add day number picker, eg. last week, last month, last 3, 6, 12, 24 months
            
            ScrollView(.horizontal) {
                HStack {
                    if daysToShow != (52 * 7) {
                        Button {
                            daysToShow = (52 * 7)
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button("day") {
                        daysToShow = 1
                    }
                    Button("week") {
                        daysToShow = 7
                    }
                    Button("month") {
                        daysToShow = (7*4)
                    }
                    Button("quarter") {
                        daysToShow = (7*13)
                    }
                    /*
                    Button("100 days") {
                        daysToShow = 100
                    }
                     */
                    Button("year") {
                        daysToShow = (7*52)
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    if boxDimensions == 15.0 {
                        boxDimensions = 30.0
                    } else {
                        boxDimensions = 15.0
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
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
    NavigationStack {
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
}
