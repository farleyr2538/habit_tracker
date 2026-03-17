//
//  FeatureRow.swift
//  Habit Tracker
//
//  Created by Rob Farley on 16/03/2026.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            
            Text(text)
                .font(.title3)
            
            Spacer()
        }
    }
}

#Preview {
    FeatureRow(
        icon: "person.fill",
        text: "Track your progress"
    )
}
