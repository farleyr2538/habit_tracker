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
    
    enum Width {
        case wide
        case narrow
    }
    var width : Width
    
    @State var scrollPosition : Int?
    
    var body: some View {
        
        let gridRows : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows) // number of rows permitted
        
        let datesInLastYear = {
            if width == .wide {
                return viewModel.datesInLast(dateComponent: .year, number: 1)
            } else {
                return viewModel.datesInLast(dateComponent: .month, number: 6)
            }
        }()
        let remainder = datesInLastYear.count % 7
        let buffer = 7 - remainder
        
        let selectedWeekdays = ["Mon", "", "Weds", "", "Fri", "", "Sun"]
        
        ScrollView([.horizontal]) {
            
            LazyHGrid(rows: gridRows) {
                
                ForEach(selectedWeekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8.0))
                }
                
                ForEach(0..<buffer, id: \.self) { x in
                    ZStack {
                        Rectangle()
                        /*
                         Text(String(index + 1))
                         .foregroundStyle(.white)
                         .font(.custom("helvetica", size: 5.0))
                         */
                    }
                    .frame(width: 10, height: 10)
                    .padding(.vertical, -3)
                    .padding(.horizontal, -3)
                    .hidden()
                }
                
                ForEach(datesInLastYear, id: \.self) { date in
                    
                    let isComplete = habit.dates.contains(date)
                    
                    ZStack {
                        Rectangle()
                            .foregroundStyle(isComplete ? .green : .gray.opacity(2.0))
                        
                        /*
                         Text(date.description)
                         .foregroundStyle(.white)
                         .font(.custom("helvetica", size: 2.0))
                         */
                        
                    }
                    .frame(width: 10, height: 10)
                    .padding(.vertical, -3)
                    .padding(.horizontal, -3)
                }
            }
            .frame(height: 90)
            .padding(.horizontal)
            .scrollTargetLayout()
            //.frame(height: 200)
        }
        .frame(height: 100)
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.trailing)
        .scrollPosition(id: $scrollPosition)
        .onAppear {
            scrollPosition = datesInLastYear.count
        }
        
    }
}

#Preview {
    let previewHabit : Habit = Habit.sampleData.first!
    
    HorizontalGitHubView(habit: previewHabit, width: .wide)
        .environmentObject(ViewModel())
}
