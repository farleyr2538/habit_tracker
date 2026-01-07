//
//  DayView.swift
//  Practice
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI

struct DayView: View {
    
    @EnvironmentObject var viewModel : ViewModel
    
    @State var pressEffect : Bool = false
    var completed : Bool
    @Binding var dates : [Date]
    
    var date : Date
    
    var dimensions = 35.0
    
    let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        
        let dayNumber = calendar.component(.day, from: date)
        
        ZStack {
            Rectangle()
                .frame(maxWidth: dimensions, maxHeight: dimensions)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(15)
                .scaleEffect(pressEffect ? 0.6 : 1)
                .foregroundStyle(completed ? .green : .black)
                .onTapGesture {
                    impact.impactOccurred()
                    withAnimation(.bouncy) {
                        pressEffect.toggle()
                        if !completed {
                            dates.append(calendar.startOfDay(for: date))
                        } else {
                            dates.removeAll { calendar.isDate($0, inSameDayAs: date) }
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        withAnimation(.bouncy) {
                            pressEffect.toggle()
                        }
                    }
                }
            Text(String(dayNumber))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    DayView(
        completed: true,
        dates: .constant([Date()]),
        date: Calendar.current.startOfDay(for: Date())
    )
        .environmentObject(ViewModel())
}
