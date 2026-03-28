//
//  StorageLocationDebugView.swift
//  Habit Tracker
//
//  Created by Rob Farley on 19/03/2026.
//
//  This view shows habits from ALL possible storage locations
//  to help identify if data is scattered across multiple databases
//

import SwiftUI
import SwiftData

struct StorageLocationDebugView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationResults: [StorageLocationResult] = []
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var currentLocationHabits: [Habit] = []
    @State private var showShareSheet = false
    @State private var reportToShare = ""
    @State private var showMergeView = false
    
    // Get current habits from the app's active database
    @Query private var activeHabits: [Habit]
    
    // Check if we have habits in the old location that could be merged
    private var canMergeOldHabits: Bool {
        locationResults.first { result in
            result.locationName.contains("App Support") &&
            result.locationName.contains("default.store") &&
            result.habitCount > 0
        } != nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This tool scans all possible storage locations where habits might have been saved during app updates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
                
                Section {
                    HStack {
                        Text("Currently Active Location")
                            .font(.headline)
                        Spacer()
                        Text("\(activeHabits.count) habits")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !activeHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Oldest habit:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let oldest = activeHabits.min(by: { $0.dateCreated < $1.dateCreated }) {
                                Text("\(oldest.name) - \(formatDate(oldest.dateCreated))")
                                    .font(.subheadline)
                            }
                            
                            Text("Newest habit:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            if let newest = activeHabits.max(by: { $0.dateCreated < $1.dateCreated }) {
                                Text("\(newest.name) - \(formatDate(newest.dateCreated))")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    ForEach(activeHabits.prefix(5)) { habit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .font(.subheadline)
                            Text("Created: \(formatDate(habit.dateCreated))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if activeHabits.count > 5 {
                        Text("... and \(activeHabits.count - 5) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if activeHabits.isEmpty {
                        Text("No habits in current database")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                } header: {
                    Text("Current Database (\(activeHabits.count))")
                } footer: {
                    if !activeHabits.isEmpty {
                        Text("Date range: Check if your missing habits fall within this timeframe.")
                    }
                }
                
                if !locationResults.isEmpty {
                    ForEach(locationResults) { result in
                        LocationResultSection(result: result)
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
                
                Section {
                    if isScanning {
                        HStack {
                            ProgressView()
                            Text("Scanning storage locations...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            scanAllLocations()
                        } label: {
                            Label("Scan All Storage Locations", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                } header: {
                    Text("Scan")
                } footer: {
                    Text("This will check all possible storage locations for habit data. Any habits found in old locations indicate why data may have appeared missing.")
                }
                
                Section {
                    Button("Export Full Report") {
                        exportReport()
                    }
                    
                    Button("Check Migration Status") {
                        checkMigrationStatus()
                    }
                    
                    Button {
                        showMergeView = true
                    } label: {
                        Label("Merge Habits from Old Location", systemImage: "arrow.triangle.merge")
                    }
                    .disabled(!canMergeOldHabits)
                } header: {
                    Text("Actions")
                } footer: {
                    if canMergeOldHabits {
                        Text("⚠️ Old habits detected! Use the merge tool to safely combine them with your current database.")
                    }
                }
            }
            .navigationTitle("Storage Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Automatically scan when view appears
                scanAllLocations()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [reportToShare])
            }
            .sheet(isPresented: $showMergeView) {
                MergeOldHabitsView()
            }
        }
    }
    
    // MARK: - Scanning Logic
    
    private func scanAllLocations() {
        isScanning = true
        locationResults = []
        errorMessage = nil
        
        // Perform scan on background thread to avoid blocking UI
        Task.detached {
            let results = await performScan()
            
            await MainActor.run {
                locationResults = results
                isScanning = false
            }
        }
    }
    
    @MainActor
    private func performScan() async -> [StorageLocationResult] {
        var results: [StorageLocationResult] = []
        let appGroupID = "group.com.rob.habittracker"
        
        // Define all possible storage locations
        let locations: [(name: String, url: URL?)] = [
            ("App Support / default.store", URL.applicationSupportDirectory.appending(path: "default.store")),
            ("App Support / HabitTracker.sqlite", URL.applicationSupportDirectory.appending(path: "HabitTracker.sqlite")),
            ("App Support / Habit_Tracker.sqlite", URL.applicationSupportDirectory.appending(path: "Habit_Tracker.sqlite")),
            ("App Group / default.store", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.appendingPathComponent("default.store")),
            ("App Group / Habit_Tracker.sqlite", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.appendingPathComponent("Habit_Tracker.sqlite")),
            ("App Group / HabitTracker.sqlite (CURRENT)", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.appendingPathComponent("HabitTracker.sqlite"))
        ]
        
        for (name, url) in locations {
            guard let url = url else {
                results.append(StorageLocationResult(
                    locationName: name,
                    url: nil,
                    exists: false,
                    fileSize: 0,
                    habits: [],
                    error: "URL not accessible"
                ))
                continue
            }
            
            let exists = FileManager.default.fileExists(atPath: url.path)
            let fileSize = calculateFileSize(at: url)
            
            // Special handling for the current active database
            if name.contains("CURRENT") && exists {
                // Use the @Query results instead of trying to open a second connection
                let snapshots = activeHabits.map { habit in
                    HabitSnapshot(
                        name: habit.name,
                        dateCreated: habit.dateCreated,
                        startFrom: habit.startFrom,
                        colorHash: habit.colorHash,
                        order: habit.order,
                        completionCount: habit.dates.count
                    )
                }
                results.append(StorageLocationResult(
                    locationName: name,
                    url: url,
                    exists: true,
                    fileSize: fileSize,
                    habits: snapshots,
                    error: nil
                ))
            } else if exists && fileSize > 0 {
                // Try to open this database and read habits
                let habits = await readHabits(from: url, locationName: name)
                results.append(StorageLocationResult(
                    locationName: name,
                    url: url,
                    exists: true,
                    fileSize: fileSize,
                    habits: habits.habits,
                    error: habits.error
                ))
            } else {
                results.append(StorageLocationResult(
                    locationName: name,
                    url: url,
                    exists: exists,
                    fileSize: fileSize,
                    habits: [],
                    error: exists ? nil : "File does not exist"
                ))
            }
        }
        
        return results
    }
    
    private func readHabits(from url: URL, locationName: String) async -> (habits: [HabitSnapshot], error: String?) {
        do {
            let schema = Schema([Habit.self])
            
            let config = ModelConfiguration(
                schema: schema,
                url: url,
                cloudKitDatabase: .none // Don't sync while scanning
            )
            
            // Try to open the container with migration plan
            let container = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: [config]
            )
            
            // Fetch habits from this database
            let context = container.mainContext
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.dateCreated)]
            )
            
            let habits = try context.fetch(descriptor)
            
            print("✅ Successfully read \(habits.count) habits from \(locationName)")
            
            // Create snapshots (not the actual Habit objects, to avoid context issues)
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
            
            return (snapshots, nil)
            
        } catch {
            print("❌ Error reading from \(locationName): \(error)")
            return ([], "Error: \(error.localizedDescription)")
        }
    }
    
    private func calculateFileSize(at url: URL) -> Int {
        let directory = url.deletingLastPathComponent()
        let storeName = url.lastPathComponent
        let relatedFiles = [storeName, storeName + "-wal", storeName + "-shm"]
        
        var totalSize = 0
        for fileName in relatedFiles {
            let fileURL = directory.appending(path: fileName)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int {
                totalSize += size
            }
        }
        return totalSize
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func exportReport() {
        var report = """
        STORAGE LOCATION DIAGNOSTIC REPORT
        Generated: \(Date())
        
        =====================================
        CURRENT ACTIVE DATABASE
        =====================================
        Habits Found: \(activeHabits.count)
        
        """
        
        for habit in activeHabits.sorted(by: { $0.dateCreated < $1.dateCreated }) {
            report += "- \(habit.name) (created \(formatDate(habit.dateCreated)))\n"
        }
        
        report += "\n=====================================\n"
        report += "ALL STORAGE LOCATIONS\n"
        report += "=====================================\n\n"
        
        for result in locationResults {
            report += "[\(result.locationName)]\n"
            report += "Exists: \(result.exists ? "YES" : "NO")\n"
            if result.exists {
                report += "Size: \(formatFileSize(result.fileSize))\n"
                report += "Habits: \(result.habits.count)\n"
                
                for habit in result.habits.sorted(by: { $0.dateCreated < $1.dateCreated }) {
                    report += "  - \(habit.name) (created \(formatDate(habit.dateCreated)), \(habit.completionCount) completions)\n"
                }
                
                if let error = result.error {
                    report += "Error: \(error)\n"
                }
            }
            report += "\n"
        }
        
        report += """
        =====================================
        SUMMARY
        =====================================
        Total unique habits across all locations:
        """
        
        // Collect all unique habits
        var allHabits = Set<String>()
        for result in locationResults where result.exists {
            for habit in result.habits {
                allHabits.insert("\(habit.name) - \(formatDate(habit.dateCreated))")
            }
        }
        
        report += "\n\(allHabits.count) unique habits found\n\n"
        
        for habitInfo in allHabits.sorted() {
            report += "- \(habitInfo)\n"
        }
        
        // Copy to clipboard AND show share sheet
        UIPasteboard.general.string = report
        reportToShare = report
        showShareSheet = true
        
        print("📋 Report copied to clipboard!")
        print(report)
    }
    
    private func checkMigrationStatus() {
        let migrationComplete = UserDefaults.standard.bool(forKey: AppGroupMigration.migrationCompleteKey)
        let schemaVerified = UserDefaults.standard.bool(forKey: AppGroupMigration.schemaMigrationVerifiedKey)
        
        errorMessage = """
        Migration Status:
        
        App Group Migration: \(migrationComplete ? "✅ Complete" : "⚠️ Not Run")
        Schema Verification: \(schemaVerified ? "✅ Complete" : "⚠️ Not Run")
        
        Active Database: \(activeHabits.count) habits
        """
    }
}

// MARK: - Supporting Types

struct StorageLocationResult: Identifiable {
    let id = UUID()
    let locationName: String
    let url: URL?
    let exists: Bool
    let fileSize: Int
    let habits: [HabitSnapshot]
    let error: String?
    
    var hasData: Bool {
        fileSize > 0
    }
    
    var habitCount: Int {
        habits.count
    }
}

struct HabitSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let dateCreated: Date
    let startFrom: Date
    let colorHash: String?
    let order: Int
    let completionCount: Int
}

// MARK: - Location Result Section View

struct LocationResultSection: View {
    let result: StorageLocationResult
    
    var body: some View {
        Section {
            if result.exists {
                HStack {
                    Text("File Size")
                    Spacer()
                    Text(formatFileSize(result.fileSize))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Habits Found")
                    Spacer()
                    Text("\(result.habitCount)")
                        .foregroundStyle(result.habitCount > 0 ? .primary : .secondary)
                        .fontWeight(result.habitCount > 0 ? .bold : .regular)
                }
                
                if !result.habits.isEmpty {
                    ForEach(result.habits.prefix(10)) { habit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .font(.subheadline)
                            HStack {
                                Text("Created: \(formatDate(habit.dateCreated))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(habit.completionCount) completions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if result.habits.count > 10 {
                        Text("... and \(result.habits.count - 10) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = result.error {
                    Text("⚠️ \(error)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if let url = result.url {
                    Text(url.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
                
            } else {
                Text("File does not exist")
                    .foregroundStyle(.secondary)
                    .italic()
            }
        } header: {
            HStack {
                Text(result.locationName)
                Spacer()
                if result.exists && result.habitCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } footer: {
            if result.exists && result.habitCount > 0 {
                Text("⚠️ This location contains \(result.habitCount) habit(s) that may not be visible in the current app database!")
                    .foregroundStyle(.orange)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - ShareSheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - Preview

#Preview {
    StorageLocationDebugView()
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
}
