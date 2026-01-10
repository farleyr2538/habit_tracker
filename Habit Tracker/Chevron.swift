//
//  Chevron.swift
//  Habit Tracker
//
//  Created by Rob Farley on 07/01/2026.
//

import SwiftUI

struct Chevron: View {
    
    var direction : Direction
    
    var body: some View {
                            
        ZStack {
            RoundedRectangle(cornerRadius: 8.0)
                .foregroundColor(.secondary.opacity(0.1))
                .frame(width: 20, height: 90)
            if direction == .left {
                Image(systemName: "chevron.left")
            } else {
                Image(systemName: "chevron.right")
            }
        }
        
    }
}

#Preview {
    Chevron(direction: .left)
}
