//
//  MergeOldHabitsView.swift
//  Habit Tracker
//
//  Tool to merge habits from old storage location into current database
//

import SwiftUI
import SwiftData

struct MergeOldHabitsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var currentHabits: [Habit]
    
    @State private var oldHabits: [HabitSnapshot] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var mergeStrategy: MergeStrategy = .smart
    @State private var showingConfirmation = false
    @State private var mergeComplete = false
    @State private var mergeReport = ""
    
    enum MergeStrategy: String, CaseIterable {
        case smart = "Smart Merge"
        case addAll = "Add All as New"
        case mergeOnly = "Merge Existing Only"
        
        var description: String {
            switch self {
            case .smart:
                return "Merge habits with matching names, add unique ones as new"
            case .addAll:
                return "Add all old habits as new (may create duplicates)"
            case .mergeOnly:
                return "Only update habits that already exist (same name)"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if mergeComplete {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Merge Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(mergeReport)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            } else {
                List {
                    Section {
                        Text("Found \(oldHabits.count) habits in the old storage location (App Support/default.store)")
                            .font(.subheadline)
                    } header: {
                        Text("Old Habits Detected")
                    }
                    
                    if isLoading {
                        Section {
                            HStack {
                                ProgressView()
                                Text("Loading old habits...")
                            }
                        }
                    } else if !oldHabits.isEmpty {
                        Section {
                            ForEach(oldHabits) { habit in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(habit.name)
                                            .font(.headline)
                                        
                                        Text("\(habit.completionCount) completions")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("Created: \(formatDate(habit.dateCreated))")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    if currentHabits.contains(where: { $0.name == habit.name }) {
                                        Image(systemName: "arrow.triangle.merge")
                                            .foregroundStyle(.orange)
                                    } else {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        } header: {
                            Text("Habits to Merge")
                        } footer: {
                            Text("🟢 = Will be added as new\n🟠 = Will be merged with existing")
                        }
                        
                        Section {
                            Picker("Merge Strategy", selection: $mergeStrategy) {
                                ForEach(MergeStrategy.allCases, id: \.self) { strategy in
                                    Text(strategy.rawValue).tag(strategy)
                                }
                            }
                            .pickerStyle(.inline)
                            
                            Text(mergeStrategy.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text("Options")
                        }
                        
                        Section {
                            Button(action: {
                                showingConfirmation = true
                            }) {
                                Label("Merge Habits", systemImage: "arrow.triangle.merge")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        } header: {
                            Text("Error")
                        }
                    }
                }
                .navigationTitle("Merge Old Habits")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .task {
                    await loadOldHabits()
                }
                .confirmationDialog(
                    "Confirm Merge",
                    isPresented: $showingConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Merge \(oldHabits.count) Habits", role: .destructive) {
                        performMerge()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will merge \(oldHabits.count) habits from the old location into your current database. This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Loading
    
    private func loadOldHabits() async {
        do {
            let oldStoreURL = URL.applicationSupportDirectory.appending(path: "default.store")
            
            guard FileManager.default.fileExists(atPath: oldStoreURL.path) else {
                await MainActor.run {
                    errorMessage = "No old database found"
                    isLoading = false
                }
                return
            }
            
            // Open the old database
            let schema = Schema([Habit.self])
            let oldConfig = ModelConfiguration(
                schema: schema,
                url: oldStoreURL,
                cloudKitDatabase: .none
            )
            
            let oldContainer = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: [oldConfig]
            )
            
            let oldContext = oldContainer.mainContext
            let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.dateCreated)])
            let habits = try oldContext.fetch(descriptor)
            
            // Create snapshots
            let snapshots = habits.map { habit in
                HabitSnapshot(
                    name: habit.name,
                    dateCreated: habit.dateCreated,
                    startFrom: habit.startFrom,
                    colorHash: habit.colorHash,
                    order: habit.order,
                    completionCount: habit.dates.count
                )
            }
            
            await MainActor.run {
                oldHabits = snapshots
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load old habits: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Merging
    
    private func performMerge() {
        Task {
            do {
                let report = try await executeMerge()
                await MainActor.run {
                    mergeReport = report
                    mergeComplete = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Merge failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func executeMerge() async throws -> String {
        // Re-open the old database to get full habit data
        let oldStoreURL = URL.applicationSupportDirectory.appending(path: "default.store")
        let schema = Schema([Habit.self])
        let oldConfig = ModelConfiguration(
            schema: schema,
            url: oldStoreURL,
            cloudKitDatabase: .none
        )
        
        let oldContainer = try ModelContainer(
            for: schema,
            migrationPlan: MigrationPlan.self,
            configurations: [oldConfig]
        )
        
        let oldContext = oldContainer.mainContext
        let descriptor = FetchDescriptor<Habit>()
        let oldHabitsData = try oldContext.fetch(descriptor)
        
        var merged = 0
        var added = 0
        var skipped = 0
        
        for oldHabit in oldHabitsData {
            switch mergeStrategy {
            case .smart:
                // Check if habit exists
                if let existingHabit = currentHabits.first(where: { $0.name == oldHabit.name }) {
                    // Merge dates
                    let combinedDates = Set(existingHabit.dates + oldHabit.dates)
                    existingHabit.dates = Array(combinedDates).sorted()
                    
                    // Keep the earlier creation date
                    if oldHabit.dateCreated < existingHabit.dateCreated {
                        existingHabit.dateCreated = oldHabit.dateCreated
                    }
                    
                    // Keep the earlier startFrom date
                    if oldHabit.startFrom < existingHabit.startFrom {
                        existingHabit.startFrom = oldHabit.startFrom
                    }
                    
                    merged += 1
                } else {
                    // Add as new
                    let newHabit = Habit(
                        name: oldHabit.name,
                        dates: oldHabit.dates,
                        colorHash: oldHabit.colorHash,
                        dateCreated: oldHabit.dateCreated,
                        startFrom: oldHabit.startFrom,
                        order: currentHabits.count + added
                    )
                    modelContext.insert(newHabit)
                    added += 1
                }
                
            case .addAll:
                // Add all as new
                let newHabit = Habit(
                    name: oldHabit.name,
                    dates: oldHabit.dates,
                    colorHash: oldHabit.colorHash,
                    dateCreated: oldHabit.dateCreated,
                    startFrom: oldHabit.startFrom,
                    order: currentHabits.count + added
                )
                modelContext.insert(newHabit)
                added += 1
                
            case .mergeOnly:
                // Only merge existing
                if let existingHabit = currentHabits.first(where: { $0.name == oldHabit.name }) {
                    let combinedDates = Set(existingHabit.dates + oldHabit.dates)
                    existingHabit.dates = Array(combinedDates).sorted()
                    
                    if oldHabit.dateCreated < existingHabit.dateCreated {
                        existingHabit.dateCreated = oldHabit.dateCreated
                    }
                    
                    if oldHabit.startFrom < existingHabit.startFrom {
                        existingHabit.startFrom = oldHabit.startFrom
                    }
                    
                    merged += 1
                } else {
                    skipped += 1
                }
            }
        }
        
        // Save the changes
        try modelContext.save()
        
        // Build report
        var report = ""
        if merged > 0 {
            report += "✅ Merged \(merged) habit\(merged == 1 ? "" : "s")\n"
        }
        if added > 0 {
            report += "➕ Added \(added) new habit\(added == 1 ? "" : "s")\n"
        }
        if skipped > 0 {
            report += "⏭️ Skipped \(skipped) habit\(skipped == 1 ? "" : "s")\n"
        }
        
        return report
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    MergeOldHabitsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
