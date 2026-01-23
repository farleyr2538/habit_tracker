//
//  DayBox.swift
//  Habit Tracker
//
//  Created by Rob Farley on 22/01/2026.
//

import SwiftUI

struct DayBox: View {
    
    var dayNumber: Int
    var dimensions = 35.0
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: dimensions, height: dimensions)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(10)

            Text(String(dayNumber))
                .foregroundStyle(.white)
                .font(.system(size: 16))
        }
    }
}

#Preview {
    DayBox(
        dayNumber: 5
    )
}
