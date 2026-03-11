//
//  Habit_Tracker_Widget.swift
//  Habit Tracker Widget
//
//  Created by Rob Farley on 03/02/2026.
//

import WidgetKit
import SwiftUI
import SwiftData

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

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        // Set up the same SwiftData container as the main app
        let schema = Schema([Habit.self])

        // Use shared app group container to access the same data as the main app
        let appGroupID = "group.com.rob.habittracker"
        let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
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
        SimpleEntry(date: Date(), habit: Optional<HabitSnapshot>.none)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Fetch real data for preview/snapshot
        Task {
            let entry = await fetchFirstHabit()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch the habit data and create a timeline
        Task {
            let entry = await fetchFirstHabit()
            
            // Update at the start of the next day so completion status stays accurate
            let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
            
            let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchFirstHabit() async -> SimpleEntry {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.dateCreated)]
        )
        
        do {
            let habits = try context.fetch(descriptor)
            if let firstHabit = habits.first {
                let snapshot = HabitSnapshot(from: firstHabit)
                return SimpleEntry(date: Date(), habit: snapshot)
            } else {
                return SimpleEntry(date: Date(), habit: Optional<HabitSnapshot>.none)
            }
        } catch {
            print("Error fetching habits for widget: \(error)")
            return SimpleEntry(date: Date(), habit: Optional<HabitSnapshot>.none)
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
}

// MARK: - Widget View
struct Habit_Tracker_WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if let habit = entry.habit {
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
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
    
    SimpleEntry(date: .now, habit: sampleHabit)
    SimpleEntry(date: .now, habit: nil)
}
