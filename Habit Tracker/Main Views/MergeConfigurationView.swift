//
//  MergeConfigurationView.swift
//  Habit Tracker
//
//  Configuration screen for merging habits
//

import SwiftUI
import SwiftData

struct MergeConfigurationView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let habitsToMerge: [Habit]
    let onComplete: () -> Void
    
    @State private var selectedNameIndex = 0
    @State private var customName = ""
    @State private var useCustomName = false
    @State private var showingConfirmation = false
    @State private var mergeError: String?
    
    private var totalCompletions: Int {
        Set(habitsToMerge.flatMap { $0.dates }).count
    }
    
    private var earliestDate: Date {
        habitsToMerge.map { $0.dateCreated }.min() ?? Date()
    }
    
    private var earliestStartFrom: Date {
        habitsToMerge.map { $0.startFrom }.min() ?? Date()
    }
    
    private var finalName: String {
        if useCustomName {
            return customName.isEmpty ? habitsToMerge[selectedNameIndex].name : customName
        } else {
            return habitsToMerge[selectedNameIndex].name
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Merging \(habitsToMerge.count) habits:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(habitsToMerge) { habit in
                            HStack {
                                Circle()
                                    .fill(Color(hex: habit.colorHash ?? ""))
                                    .frame(width: 8, height: 8)
                                
                                Text(habit.name)
                                    .font(.callout)
                                
                                Spacer()
                                
                                Text("\(habit.dates.count) completions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Habits to Merge")
                }
                
                Section {
                    Toggle("Use Custom Name", isOn: $useCustomName.animation())
                    
                    if useCustomName {
                        TextField("Custom name", text: $customName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Picker("Choose Name", selection: $selectedNameIndex) {
                            ForEach(Array(habitsToMerge.enumerated()), id: \.offset) { index, habit in
                                Text(habit.name).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Merged Habit Name")
                } footer: {
                    Text("This will be the name of the merged habit.")
                }
                
                Section {
                    HStack {
                        Text("Total Completions")
                        Spacer()
                        Text("\(totalCompletions)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Earliest Creation Date")
                        Spacer()
                        Text(earliestDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: habitsToMerge[selectedNameIndex].colorHash ?? ""))
                                .frame(width: 20, height: 20)
                            Text("From selected habit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Merge Preview")
                } footer: {
                    Text("The merged habit will combine all completion dates from the selected habits. Duplicate dates will be automatically removed.")
                }
                
                Section {
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Label("Merge Habits", systemImage: "arrow.triangle.merge")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.blue)
                } footer: {
                    Text("⚠️ This action cannot be undone. The selected habits will be deleted and replaced with a single merged habit.")
                        .foregroundStyle(.orange)
                }
                
                if let mergeError = mergeError {
                    Section {
                        Text(mergeError)
                            .foregroundStyle(.red)
                    } header: {
                        Text("Error")
                    }
                }
            }
            .navigationTitle("Configure Merge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Confirm Merge",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Merge into \"\(finalName)\"", role: .destructive) {
                    performMerge()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will merge \(habitsToMerge.count) habits into one. The other \(habitsToMerge.count - 1) habit\(habitsToMerge.count - 1 == 1 ? " will" : "s will") be deleted. This cannot be undone.")
            }
        }
    }
    
    private func performMerge() {
        do {
            // Collect all unique dates
            let allDates = Set(habitsToMerge.flatMap { $0.dates })
            let sortedDates = Array(allDates).sorted()
            
            // Keep the first selected habit as the base
            let baseHabit = habitsToMerge[selectedNameIndex]
            
            // Update the base habit
            baseHabit.name = finalName
            baseHabit.dates = sortedDates
            baseHabit.dateCreated = earliestDate
            baseHabit.startFrom = earliestStartFrom
            
            // Delete the other habits
            for (index, habit) in habitsToMerge.enumerated() {
                if index != selectedNameIndex {
                    modelContext.delete(habit)
                }
            }
            
            // Save changes
            try modelContext.save()
            
            // Complete successfully
            onComplete()
            
        } catch {
            mergeError = "Failed to merge habits: \(error.localizedDescription)"
        }
    }
}

#Preview {
    MergeConfigurationView(
        habitsToMerge: [
            Habit(name: "Exercise", dates: [Date()], colorHash: "FF5733"),
            Habit(name: "Read", dates: [Date(), Date().addingTimeInterval(-86400)], colorHash: "3498DB"),
            Habit(name: "Meditate", dates: [Date()], colorHash: "2ECC71")
        ],
        onComplete: {}
    )
    .modelContainer(for: Habit.self, inMemory: true)
}
