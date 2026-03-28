//
//  HabitCompletionBarChart.swift
//  Habit Tracker
//
//  Created by Rob Farley on 30/01/2026.
//

import SwiftUI
import SwiftData

struct HabitCompletionBarChart: View {
    
    @Environment(ViewModel.self) var viewModel
    @Query var habits: [Habit]
    
    @State private var dayScores: [Double] = []
    @State private var daysToShow: Int = 30
    
    var body: some View {
        
        VStack {
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Bar chart
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(Array(dayScores.suffix(daysToShow).enumerated()), id: \.offset) { index, score in
                            VStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(score == 0 ? Color.gray.opacity(0.1) : Color.green.opacity(0.8))
                                    .frame(height: max(4, score * 200))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    // Time period selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            TimeButton(title: "Week", days: 7, selected: daysToShow == 7) {
                                daysToShow = 7
                            }
                            TimeButton(title: "Month", days: 30, selected: daysToShow == 30) {
                                daysToShow = 30
                            }
                            TimeButton(title: "Quarter", days: 90, selected: daysToShow == 90) {
                                daysToShow = 90
                            }
                            TimeButton(title: "Year", days: 365, selected: daysToShow == 365) {
                                daysToShow = 365
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.background, ignoresSafeAreaEdges: .all)
        .onAppear {
            dayScores = viewModel.createDayScores(habits: habits)
        }
    }
}

struct TimeButton: View {
    let title: String
    let days: Int
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(selected ? .accentColor : .gray)
    }
}

#Preview {
    NavigationStack {
        HabitCompletionBarChart()
            .environment(ViewModel())
            .modelContainer(for: Habit.self, inMemory: true) { result in
                if case .success(let container) = result {
                    Habit.sampleData.forEach { habit in
                        container.mainContext.insert(habit)
                    }
                }
            }
    }
}
