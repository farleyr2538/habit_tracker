//
//  VerticalAllHabitsGrid.swift
//  Habit Tracker
//
//  Created by Rob Farley on 20/01/2026.
//

import SwiftUI
import SwiftData

struct VerticalAllHabitsGrid: View {
    
    @Environment(ViewModel.self) var viewModel
    
    @Query var habits : [Habit]
    
    @State var opacities : [Double] = []
    @Environment(\.modelContext) var context
    
    @State var infoSheetShowing : Bool = false
    
    @State var daysToShow : Int = 52 * 7
    @State var numberOfCols : Int = 7
    
    @State var scrollPosition : Int?
    
    @State var isZoomed : Bool = true
    
    let smallBoxDimensions : Double = 15.0
    let largeBoxDimensions : Double = 30.0
    
    var textSize = 10.0
    
    let allWeekdays = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        
        let selectedWeekdaysArray = Array(allWeekdays.enumerated())
        
        let gridCols : [GridItem] = Array(
            repeating: GridItem(
                .fixed(isZoomed ? largeBoxDimensions : smallBoxDimensions),
                spacing: 5.0
            ),
            count: numberOfCols) // number of rows permitted
                        
        VStack {
            
            VStack {
                
                LazyVGrid(columns: gridCols) {
                    ForEach(selectedWeekdaysArray, id: \.offset) { index, day in
                        Text(day)
                            .font(.system(size: textSize))
                            .frame(width: isZoomed ? largeBoxDimensions : smallBoxDimensions)
                    }
                }
                .padding(.top)
                .animation(.smooth(duration: 0.4), value: isZoomed)
                
                ScrollView([.vertical]) {
                    
                    LazyVGrid(columns: gridCols, spacing: 5.0) {
                        
                        ForEach(0..<opacities.count, id: \.self) { dayNumber in
                            
                            RoundedRectangle(cornerRadius: isZoomed ? 4.0 : 2.5)
                                .foregroundStyle(opacities[dayNumber] == 0 ? Color.gray.opacity(0.1) : Color.green.opacity(opacities[dayNumber]))
                                .frame(
                                    width: isZoomed ? largeBoxDimensions : smallBoxDimensions,
                                    height: isZoomed ? largeBoxDimensions : smallBoxDimensions
                                )
                                //.padding(.vertical, -1)
                        }
                        
                    }
                    .id(isZoomed) // Add this to force view recreation
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.bottom)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $scrollPosition, anchor: .bottom)
                .padding(.bottom, 20)
                
            }
            .padding(.horizontal, isZoomed ? 20 : 120)
            .animation(.smooth(duration: 0.4), value: isZoomed)
            
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
        .background(Color.background, ignoresSafeAreaEdges: .all)
        
        .onAppear {
            opacities = viewModel.createDayScores(habits: habits)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.smooth(duration: 0.4)) {
                        isZoomed.toggle()
                    }
                } label: {
                    Image(systemName: isZoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
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
            .environment(ViewModel())
            .modelContainer(for: Habit.self, inMemory: true) { result in
                if case .success(let container) = result {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    // Create habits with recent completions
                    var runningDates: [Date] = []
                    var yogaDates: [Date] = []
                    var readingDates: [Date] = []
                    
                    // Running: completed most days in the last 30 days
                    for daysAgo in [0, 1, 2, 3, 5, 6, 8, 10, 11, 12, 14, 15, 17, 18, 20, 22, 24, 25, 27, 29] {
                        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                            runningDates.append(date)
                        }
                    }
                    
                    // Yoga: completed less frequently
                    for daysAgo in [0, 2, 4, 7, 9, 14, 16, 21, 28] {
                        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                            yogaDates.append(date)
                        }
                    }
                    
                    // Reading: sporadic pattern
                    for daysAgo in [0, 1, 3, 4, 8, 10, 15, 18, 22, 25, 26, 30, 32, 35, 40, 45] {
                        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                            readingDates.append(date)
                        }
                    }
                    
                    let startDate = calendar.date(byAdding: .day, value: -60, to: today)!
                    
                    let habits = [
                        Habit(name: "Running", dates: runningDates, colorHash: "#00FF00", dateCreated: startDate, startFrom: startDate, order: 0),
                        Habit(name: "Yoga", dates: yogaDates, colorHash: "#FF6B6B", dateCreated: startDate, startFrom: startDate, order: 1),
                        Habit(name: "Reading", dates: readingDates, colorHash: "#4ECDC4", dateCreated: startDate, startFrom: startDate, order: 2)
                    ]
                    
                    habits.forEach { habit in
                        container.mainContext.insert(habit)
                    }
                }
            }
    }
}
