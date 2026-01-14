//
//  GitHubView.swift
//  Practice
//
//  Created by Robert Farley on 26/05/2025.
//

import SwiftUI

struct VerticalGitHubView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var numberOfDays : Int = 365
    @State var numberOfCols = 7
    
    var body: some View {
        
        let gridCols : [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfCols) // number of cols permitted
        
        // get weekday, and adjust it to 1 = Monday, 2 = Tuesday, etc.
        let currentDay = {
            let hypothesis = calendar.component(.weekday, from: Date())
            if hypothesis == 1 {
                return 6
            } else if hypothesis == 2 {
                return 7
            } else {
                return hypothesis
            }
        }
        // eg. if Sunday: 1, if Thursday: 5
        // we need to have this many - 1 days on the last row
        // therefore, we need this many - 1 spaces on the first row?
        
        LazyVGrid(columns: gridCols) {
            ForEach(0..<numberOfDays + (currentDay()), id: \.self) { index in
                if index >= (currentDay()) {
                    ZStack {
                        Rectangle()
                        Text(String(index))
                            .foregroundStyle(.white)
                            .font(.custom("helvetica", size: 5.0))
                    }
                    .frame(width: 10, height: 10)
                    .padding(.vertical, -3)
                    
                        
                } else {
                    Spacer()
                        .padding(.vertical, -3)
                }
            }
        }
        .frame(height: 675)
        HStack {
            Button("Year") {
                numberOfCols = 7
                numberOfDays = 365
            }
            Button("Month") {
                if let daysInMonthRange = calendar.range(of: .day, in: .month, for: Date()) {
                    numberOfCols = 7
                    numberOfDays = daysInMonthRange.count
                }
            }
            Button("Week") {
                numberOfCols = 7
                numberOfDays = 7
            }
            Button("Day") {
                numberOfCols = 1
                numberOfDays = 1
            }
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    VerticalGitHubView()
        .environmentObject(ViewModel())
}
