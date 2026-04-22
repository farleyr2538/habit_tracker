//
//  HabitSelectionRow.swift
//  Habit Tracker
//
//  Reusable view for displaying a habit with a selection indicator
//

import SwiftUI
import SwiftData

struct HabitSelectionRow: View {
    let habit: Habit
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)
                
                
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // Habit color indicator
                        Circle()
                            .fill(Color(hex: habit.colorHash ?? ""))
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("\(habit.dates.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Text("Created \(habit.dateCreated, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        HabitSelectionRow(
            habit: Habit(
                name: "Exercise",
                dates: [Date()],
                colorHash: "FF5733"
            ),
            isSelected: true,
            onTap: {}
        )
        
        HabitSelectionRow(
            habit: Habit(
                name: "Read",
                dates: [Date(), Date().addingTimeInterval(-86400)],
                colorHash: "3498DB"
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
