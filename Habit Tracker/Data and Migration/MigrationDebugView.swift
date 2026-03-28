//
//  MigrationDebugView.swift
//  Habit Tracker
//
//  Debug view for testing and resetting migrations on device
//

import SwiftUI
import SwiftData

struct MigrationDebugView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var message: String = ""
    @State private var showAlert = false
    @State private var isResetting = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This view helps you test and debug SwiftData migrations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
                
                Section {
                    Button("Check Current Data") {
                        checkCurrentData()
                    }
                    
                    Button("Verify Order Values") {
                        verifyOrderValues()
                    }
                    
                    Button("Fix Duplicate Orders") {
                        fixDuplicateOrders()
                    }
                } header: {
                    Text("Diagnostics")
                }
                
                Section {
                    Button("Create V1-Style Test Habit") {
                        createV1StyleHabit()
                    }
                    
                    Button("Create V2-Style Test Habit") {
                        createV2StyleHabit()
                    }
                    
                    Button("Create V3 Test Habit") {
                        createV3Habit()
                    }
                } header: {
                    Text("Test Data")
                }
                
                Section {
                    Button("Reset All Migration Flags") {
                        resetMigrationFlags()
                    }
                    .foregroundStyle(.orange)
                    
                    Button("Delete All Habits (Careful!)", role: .destructive) {
                        deleteAllHabits()
                    }
                    .disabled(isResetting)
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Resetting migration flags will cause migrations to re-run on next app launch. Deleting habits is permanent!")
                }
            }
            .navigationTitle("Migration Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Result", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(message)
            }
        }
    }
    
    // MARK: - Diagnostic Functions
    
    private func checkCurrentData() {
        do {
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.order)]
            )
            let habits = try modelContext.fetch(descriptor)
            
            var details = "Found \(habits.count) habit(s):\n\n"
            
            for (index, habit) in habits.enumerated() {
                details += "\(index + 1). \(habit.name)\n"
                details += "   Order: \(habit.order)\n"
                details += "   Created: \(formatDate(habit.dateCreated))\n"
                details += "   Start From: \(formatDate(habit.startFrom))\n"
                details += "   Dates count: \(habit.dates.count)\n\n"
            }
            
            message = details
            showAlert = true
            
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func verifyOrderValues() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            let orders = habits.map { $0.order }
            let uniqueOrders = Set(orders)
            
            if uniqueOrders.count != habits.count {
                let duplicates = orders.count - uniqueOrders.count
                message = "⚠️ Found \(duplicates) duplicate order value(s)!\n\nOrders: \(orders.sorted())\n\nTap 'Fix Duplicate Orders' to resolve."
            } else {
                message = "✅ All \(habits.count) habits have unique order values.\n\nOrders: \(orders.sorted())"
            }
            
            showAlert = true
            
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func fixDuplicateOrders() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            // Sort by dateCreated and reassign orders
            let sortedHabits = habits.sorted { $0.dateCreated < $1.dateCreated }
            
            for (index, habit) in sortedHabits.enumerated() {
                habit.order = index
            }
            
            try modelContext.save()
            
            message = "✅ Fixed order values for \(habits.count) habit(s)."
            showAlert = true
            
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - Test Data Creation
    
    private func createV1StyleHabit() {
        // Simulate what a V1 habit would look like after migration
        let habit = Habit(
            name: "V1-Style Test Habit",
            dates: [],
            colorHash: nil,
            dateCreated: calendar.startOfDay(for: Date()),
            startFrom: calendar.startOfDay(for: Date()),
            order: 999  // Will need manual fixing
        )
        
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            message = "✅ Created V1-style test habit.\n\nNote: Order value is 999 to simulate migration issue."
            showAlert = true
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func createV2StyleHabit() {
        // Simulate what a V2 habit would look like after migration
        let habit = Habit(
            name: "V2-Style Test Habit",
            dates: [calendar.startOfDay(for: Date())],
            colorHash: "blue",
            dateCreated: calendar.startOfDay(for: Date()),
            startFrom: calendar.startOfDay(for: Date()),
            order: 0  // All V2 habits might have order 0
        )
        
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            message = "✅ Created V2-style test habit.\n\nNote: Order value is 0 to simulate V2→V3 migration issue."
            showAlert = true
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func createV3Habit() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let existingHabits = try modelContext.fetch(descriptor)
            let nextOrder = existingHabits.map { $0.order }.max() ?? -1
            
            let habit = Habit(
                name: "V3 Test Habit",
                dates: [],
                colorHash: "green",
                dateCreated: calendar.startOfDay(for: Date()),
                startFrom: calendar.startOfDay(for: Date()),
                order: nextOrder + 1
            )
            
            modelContext.insert(habit)
            try modelContext.save()
            
            message = "✅ Created properly ordered V3 habit.\n\nOrder: \(nextOrder + 1)"
            showAlert = true
            
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - Danger Zone Functions
    
    private func resetMigrationFlags() {
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.migrationCompleteKey)
        UserDefaults.standard.removeObject(forKey: AppGroupMigration.schemaMigrationVerifiedKey)
        
        message = "✅ Migration flags reset.\n\nRestart the app to re-run migrations.\n\n⚠️ Warning: This won't delete your current data, but may cause duplicates if the old data still exists."
        showAlert = true
    }
    
    private func deleteAllHabits() {
        isResetting = true
        
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            let count = habits.count
            
            for habit in habits {
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            
            message = "✅ Deleted \(count) habit(s).\n\nYou can now test with a clean slate."
            showAlert = true
            
        } catch {
            message = "Error: \(error.localizedDescription)"
            showAlert = true
        }
        
        isResetting = false
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    MigrationDebugView()
        .environment(SubscriptionManager())
        .modelContainer(for: Habit.self, inMemory: true)
}
