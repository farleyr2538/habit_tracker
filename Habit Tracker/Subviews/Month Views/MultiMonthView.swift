//
//  SwiftUIView.swift
//  Practice
//
//  Created by Robert Farley on 18/05/2025.
//

import SwiftUI
import SwiftData

struct MultiMonthView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @Bindable var habit : Habit
    @State var months : [Date] = []
    @State var today : Date? = nil
    
    @Binding var color : Color?
    
    var body: some View {
        
        // let today = Date()
        let sixMonthsAgo = calendar.startOfDay(
            for: calendar.date(
                byAdding: .month,
                value: -12,
                to: today ?? calendar.startOfDay(for: Date())
            )!
        )
        
        VStack(alignment: .center) {
                                                
            HStack {
                
                /*
                Chevron(direction: .left)
                
                    .onTapGesture {
                        // decrement month by one
                        if let newSelectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                            selectedDate = newSelectedDate
                        }
                        
                    }
                 */
                
                ScrollView(.horizontal) {
                    
                    LazyHStack(spacing: 0) {
                        
                        ForEach(months, id:\.self) { month in
                            SingleMonthView(
                                habit: habit,
                                selectedDate: month,
                                color: $color
                            )
                                .containerRelativeFrame(.horizontal)
                                .id(month)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $today)
                //.frame(maxHeight: 400)
                
                /*
                Chevron(direction: .right)
                
                    .onTapGesture {
                        // incredment month by 1
                        if let newSelectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                            selectedDate = newSelectedDate
                        }
                    }
                */
            }
        }
        .onAppear {
            
            today = calendar.startOfDay(for: Date())
            
            for i in 0..<24 {
                let date = calendar.date(byAdding: .month, value: i, to: sixMonthsAgo)!
                months.append(date)
            }
        
        }
    }
}

#Preview {
    MultiMonthView(
        // selectedDate: Date(),
        habit: Habit(name: "Running", dates: [Date()]),
        color: .constant(nil)
    )
        .environmentObject(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true)
}
