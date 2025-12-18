//
//  MonthIncrementer.swift
//  Practice
//
//  Created by Robert Farley on 18/05/2025.
//

import SwiftUI

struct MonthIncrementer: View {
    
    var text : String
    
    var body: some View {
        ZStack {
            Circle()
                .frame(height: 75.0)
            Text(text)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    MonthIncrementer(text: "Next")
}
