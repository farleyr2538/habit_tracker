//
//  SwiftUIView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 22/01/2026.
//

import SwiftUI

struct CustomColorPicker: View {
    
    @Binding var selectedColor : Color
    var todaysDate = calendar.component(.day, from: Date())
    let colors : [Color] = [.green, .mint, .teal, .blue, .indigo,  .yellow, .orange, .red, .pink, .purple, .accent, .brown, ]
    
    var body: some View {
        
        VStack(alignment: .center) {
            HStack {
                Text("Selected color: ")
                
                Spacer()
                
                DayBox(dayNumber: todaysDate)
                    .foregroundStyle(selectedColor)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(35.0)), count: 6), spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    ZStack {
                        DayBox(dayNumber: todaysDate)
                            .foregroundStyle(color)
                            .onTapGesture {
                                selectedColor = color
                            }
                            .overlay {
                                if color == selectedColor {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(.primary.opacity(0.3), lineWidth: 3)
                                }
                            }
                    }
                    
                }
            }
            .padding(.vertical, 20)
        }
        
        
    }
}

#Preview {
    CustomColorPicker(selectedColor: .constant(.green))
}
