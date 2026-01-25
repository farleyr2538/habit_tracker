//
//  InfoSheet.swift
//  Habit Tracker
//
//  Created by Rob Farley on 19/01/2026.
//

import SwiftUI
import SwiftData

struct InfoSheet: View {
    
    @Query private var habits : [Habit]
    @Environment(\.modelContext) private var context
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                Section {
                    Text("About the All-Habits view")
                        .font(Font.title)
                    Text("Habits are only judged going back to their starting date.\n\nThis is whichever is earlier between:\n\n - the date the habit was created, or \n - the earliest date the habit was completed on.")
                    
                }
                
                Section("Your habits' start dates") {
                    ForEach(habits, id: \.self) { habit in
                        HStack {
                            Text(habit.name)
                            Spacer()
                            Text(habit.startFrom.formatted(date: .long, time: .omitted))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            //.scrollContentBackground(.automatic)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        
    }
}

#Preview {
    
    let container = try! ModelContainer(
        for: Habit.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Insert sample data once
    Habit.sampleData.forEach { habit in
        container.mainContext.insert(habit)
    }
    
    return InfoSheet()
        .modelContainer(container)
        .environmentObject(ViewModel())
}
