//
//  Habit_Tracker_Widget.swift
//  Habit Tracker Widget
//
//  Created by Rob Farley on 03/02/2026.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import StoreKit

// MARK: - Product IDs
// Product identifiers for subscription verification
enum ProductID {
    static let premiumMonthly = "com.rob.habitTracker.premiumMonthly"
    static let premiumAnnual = "com.rob.habitTracker.premiumAnnual"
}

// MARK: - Shared Constants
// Define calendar here so we don't need to import ViewModel
var calendar: Calendar = {
    var cal = Calendar.current
    cal.firstWeekday = 2  // Monday
    return cal
}()

// MARK: - Snapshot for Timeline Entry
// Since SwiftData models can't be stored directly in timeline entries,
// we create a simple snapshot with just the data we need
struct HabitSnapshot: Codable, Hashable {
    let name: String
    let dates: [Date]
    let colorHash: String?
    let dateCreated: Date
    let startFrom: Date
    
    init(from habit: Habit) {
        self.name = habit.name
        self.dates = habit.dates
        self.colorHash = habit.colorHash
        self.dateCreated = habit.dateCreated
        self.startFrom = habit.startFrom
    }
    
    // Memberwise initializer for previews and testing
    init(name: String, dates: [Date], colorHash: String?, dateCreated: Date, startFrom: Date) {
        self.name = name
        self.dates = dates
        self.colorHash = colorHash
        self.dateCreated = dateCreated
        self.startFrom = startFrom
    }
}

// MARK: - App Intent for Widget Configuration
struct HabitEntity: AppEntity {
    let id: String
    let name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    static var defaultQuery = HabitEntityQuery()
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        // Fetch habits by their IDs
        let container = try ModelContainer(
            for: Schema([Habit.self]),
            migrationPlan: MigrationPlan.self,
            configurations: [getModelConfiguration()]
        )
        
        let descriptor = FetchDescriptor<Habit>()
        let habits = try await fetchHabits(from: container, with: descriptor)
        
        // Convert identifiers back to habit entities
        let matchingHabits = habits.compactMap { habit -> HabitEntity? in
            let idString = encodeIdentifier(habit.id)
            guard identifiers.contains(idString) else { return nil }
            return HabitEntity(id: idString, name: habit.name)
        }
        
        return matchingHabits
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        // Fetch all habits for the user to choose from
        let container = try ModelContainer(
            for: Schema([Habit.self]),
            migrationPlan: MigrationPlan.self,
            configurations: [getModelConfiguration()]
        )
        
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.dateCreated)]
        )
        let habits = try await fetchHabits(from: container, with: descriptor)
        
        return habits.map { habit in
            let idString = encodeIdentifier(habit.id)
            return HabitEntity(id: idString, name: habit.name)
        }
    }
    
    @MainActor
    private func fetchHabits(from container: ModelContainer, with descriptor: FetchDescriptor<Habit>) throws -> [Habit] {
        return try container.mainContext.fetch(descriptor)
    }
    
    private func encodeIdentifier(_ identifier: PersistentIdentifier) -> String {
        // Use JSONEncoder to convert PersistentIdentifier to a stable string
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(identifier),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        // Fallback - though this should rarely happen
        return identifier.hashValue.description
    }
    
    private func getModelConfiguration() -> ModelConfiguration {
        let appGroupID = "group.com.rob.habittracker"
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Failed to get app group container")
        }
        let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")
        
        return ModelConfiguration(
            schema: Schema([Habit.self]),
            url: storeURL,
            cloudKitDatabase: .automatic
        )
    }
}

struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit"
    static var description = IntentDescription("Choose which habit to display in the widget.")
    
    @Parameter(title: "Habit")
    var habit: HabitEntity?
}

// Helper function to encode PersistentIdentifier to string
func encodeIdentifier(_ identifier: PersistentIdentifier) -> String {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(identifier),
       let string = String(data: data, encoding: .utf8) {
        return string
    }
    return identifier.hashValue.description
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        // Set up the same SwiftData container as the main app
        let schema = Schema([Habit.self])

        // Use shared app group container to access the same data as the main app
        let appGroupID = "group.com.rob.habittracker"
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Failed to get app group container")
        }
        let storeURL = appGroupContainer.appendingPathComponent("HabitTracker.sqlite")

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer for widget: \(error)")
        }
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        // Return a generic placeholder that appears instantly
        SimpleEntry(date: Date(), habit: nil, configuration: SelectHabitIntent(), isPremium: false)
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> SimpleEntry {
        // Fetch real data for preview/snapshot
        return await fetchHabit(for: configuration)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Fetch the habit data and create a timeline
        let entry = await fetchHabit(for: configuration)
        
        // Update at the start of the next day so completion status stays accurate
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
    
    // Check if user has an active premium subscription
    private func checkPremiumStatus() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProductID.premiumMonthly || 
                   transaction.productID == ProductID.premiumAnnual {
                    return true
                }
            }
        }
        return false
    }
    
    @MainActor
    private func fetchHabit(for configuration: SelectHabitIntent) async -> SimpleEntry {
        // Check premium status first
        let isPremium = await checkPremiumStatus()
        
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.dateCreated)]
        )
        
        do {
            let habits = try modelContainer.mainContext.fetch(descriptor)
            
            // Try to find the habit matching the configuration
            var selectedHabit: Habit?
            
            if let habitEntity = configuration.habit {
                selectedHabit = habits.first { habit in
                    let idString = encodeIdentifier(habit.id)
                    return idString == habitEntity.id
                }
            }
            
            // Fall back to first habit if configured habit not found or no selection
            if selectedHabit == nil {
                selectedHabit = habits.first
            }
            
            if let habit = selectedHabit {
                let snapshot = HabitSnapshot(from: habit)
                return SimpleEntry(date: Date(), habit: snapshot, configuration: configuration, isPremium: isPremium)
            } else {
                return SimpleEntry(date: Date(), habit: nil, configuration: configuration, isPremium: isPremium)
            }
        } catch {
            print("Error fetching habits for widget: \(error)")
            return SimpleEntry(date: Date(), habit: nil, configuration: configuration, isPremium: isPremium)
        }
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let habit: HabitSnapshot?
    let configuration: SelectHabitIntent
    let isPremium: Bool
}

// MARK: - Widget View
struct Habit_Tracker_WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if !entry.isPremium {
            // Show premium upsell for non-subscribers
            PremiumUpsellView()
        } else if let habit = entry.habit {
            WidgetHabitCard(habitSnapshot: habit, widgetFamily: widgetFamily)
        } else {
            // Empty state when no habits exist
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                Text("No Habits")
                    .font(.headline)
                Text("Add habits in the app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Premium Upsell View
struct PremiumUpsellView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            
            Text("Premium Feature")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Upgrade to Premium to use widgets")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Open the app to upgrade")
                .font(.caption)
                .foregroundStyle(.tertiary)
                //.padding(.top, 4)
        }
        .padding()
    }
}

// MARK: - Widget Habit Card
struct WidgetHabitCard: View {
    let habitSnapshot: HabitSnapshot
    let widgetFamily: WidgetFamily

    var body: some View {
        let color: Color = {
            if let colorHash = habitSnapshot.colorHash {
                return Color(hex: colorHash)
            } else {
                return Color.green
            }
        }()

        VStack(alignment: .leading, spacing: 16) {
            // Header with habit name
            Text(habitSnapshot.name)
                .font(.title2)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // GitHub-style contribution graph
            WidgetGitHubView(
                habitSnapshot: habitSnapshot,
                color: color,
                numberOfDays: 154,
                numberOfRows: 7
            )
        }
        .padding(15)
    }
}

// MARK: - Widget GitHub View
struct WidgetGitHubView: View {
    let habitSnapshot: HabitSnapshot
    let color: Color
    let numberOfDays: Int
    let numberOfRows: Int

    var body: some View {
        let allWeekdays = ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]
        let selectedWeekdays = ["Mon", "Weds", "Fri", "Sun"]

        let gridRows: [GridItem] = Array(repeating: GridItem(.fixed(1), spacing: 10), count: numberOfRows)

        // Calculate date range
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: (1 - numberOfDays), to: endDate)!

        LazyHGrid(rows: gridRows, spacing: 3) {
            // Weekday labels
            ForEach(allWeekdays, id: \.self) { day in
                if selectedWeekdays.contains(day) {
                    Text(day)
                        .font(.system(size: 8.0))
                        .layoutPriority(1)
                } else {
                    Spacer()
                        .layoutPriority(1)
                }
            }

            // Day squares
            ForEach(0..<numberOfDays, id: \.self) { dayNumber in
                let date = calendar.date(byAdding: .day, value: dayNumber, to: startDate)!
                let isComplete = habitSnapshot.dates.contains(date)

                RoundedRectangle(cornerRadius: 2.0)
                    .foregroundStyle(isComplete ? color : .gray.opacity(0.15))
                    .frame(width: 10, height: 10)
                    .layoutPriority(0)
            }
        }
        .frame(maxHeight: 90)
    }
}

// MARK: - Widget Configuration
struct Habit_Tracker_Widget: Widget {
    let kind: String = "Habit_Tracker_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectHabitIntent.self, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                Habit_Tracker_WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                Habit_Tracker_WidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Habit Tracker")
        .description("View your habit progress at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    Habit_Tracker_Widget()
} timeline: {
    let previewCalendar = Calendar.current
    let sampleHabit = HabitSnapshot(
        name: "Running",
        dates: [previewCalendar.startOfDay(for: Date())],
        colorHash: nil,
        dateCreated: Date(),
        startFrom: Date()
    )
    
    SimpleEntry(date: .now, habit: sampleHabit, configuration: SelectHabitIntent(), isPremium: true)
    SimpleEntry(date: .now, habit: nil, configuration: SelectHabitIntent(), isPremium: true)
    SimpleEntry(date: .now, habit: sampleHabit, configuration: SelectHabitIntent(), isPremium: false)
}
