//
//  MergeHabitsView.swift
//  Habit Tracker
//
//  User-friendly habit merge interface
//

import SwiftUI
import SwiftData

struct MergeHabitsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Habit.order) private var allHabits: [Habit]
    
    @State private var selectedHabits: Set<PersistentIdentifier> = []
    @State private var showingMergeSheet = false
    
    var canMerge: Bool {
        selectedHabits.count >= 2
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if allHabits.isEmpty {
                    ContentUnavailableView(
                        "No Habits",
                        systemImage: "checkmark.circle",
                        description: Text("Create some habits to merge them.")
                    )
                } else if allHabits.count < 2 {
                    ContentUnavailableView(
                        "Need More Habits",
                        systemImage: "checkmark.circle.badge.questionmark",
                        description: Text("You need at least 2 habits to merge.")
                    )
                } else {
                    List {
                        Section {
                            Text("Select 2 or more habits to merge together. All completion dates from the selected habits will be combined.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Section {
                            ForEach(allHabits) { habit in
                                HabitSelectionRow(
                                    habit: habit,
                                    isSelected: selectedHabits.contains(habit.persistentModelID)
                                ) {
                                    toggleSelection(for: habit)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Your Habits")
                                Spacer()
                                if !selectedHabits.isEmpty {
                                    Text("\(selectedHabits.count) selected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Merge Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        showingMergeSheet = true
                    }
                    .disabled(!canMerge)
                }
            }
            .sheet(isPresented: $showingMergeSheet) {
                if let selectedHabitObjects = getSelectedHabits() {
                    MergeConfigurationView(
                        habitsToMerge: selectedHabitObjects,
                        onComplete: {
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    private func toggleSelection(for habit: Habit) {
        if selectedHabits.contains(habit.persistentModelID) {
            selectedHabits.remove(habit.persistentModelID)
        } else {
            selectedHabits.insert(habit.persistentModelID)
        }
    }
    
    private func getSelectedHabits() -> [Habit]? {
        let selected = allHabits.filter { selectedHabits.contains($0.persistentModelID) }
        return selected.isEmpty ? nil : selected
    }
}

#Preview {
    MergeHabitsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
