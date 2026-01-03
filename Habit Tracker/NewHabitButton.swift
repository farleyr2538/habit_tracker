//
//  NewHabitButton.swift
//  Practice
//
//  Created by Robert Farley on 24/05/2025.
//

import SwiftUI

struct NewHabitButton: View {
    
    @Binding var habitEditorShowing: Bool
    
    var body: some View {
        
        if #available(iOS 26.0, *) {
            Button {
                habitEditorShowing.toggle()
            } label: {
                Text("Create my first Habit")
                    .padding(15)
            }
            .background(
                Capsule()
                    .fill(.white)
            )
            .buttonStyle(.glass)
            
        } else {
            Button {
                habitEditorShowing.toggle()
            } label: {
                Text("Create my first Habit")
                    .padding(15)
            }
            .background(Capsule())
            .buttonStyle(.borderedProminent)
        }
        
        
    }
}

#Preview {
    NewHabitButton(habitEditorShowing: .constant(false))
}
