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
        Button {
            habitEditorShowing.toggle()
        } label: {
            Text("New Habit")
                .padding(10)
        }
        .buttonBorderShape(.capsule)
        .buttonStyle(.borderedProminent)
        .foregroundStyle(.white)
        
    }
}

#Preview {
    NewHabitButton(habitEditorShowing: .constant(false))
}
