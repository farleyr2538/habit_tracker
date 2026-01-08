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
                .frame(width: dimensions, height: dimensions)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)
                .scaleEffect(pressEffect ? 0.4 : 1)
                .foregroundStyle(completed ? .green : .black)

            Text(String(dayNumber))
                .foregroundStyle(.white)
                .font(.system(size: 16))
        }
        .onTapGesture {
            
            // haptic
            impact.impactOccurred()
            
            // apply scale effect
            withAnimation(.bouncy) {
                pressEffect = true
            }
            
            if !completed {
                dates.append(calendar.startOfDay(for: date))
            } else {
                dates.removeAll { calendar.isDate($0, inSameDayAs: date) }
            }
            
            // disapply scale effect after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.bouncy) {
                    pressEffect = false
                }
            }
            
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
