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
                    Text("Habits are only judged going back to their starting date.\n\nThis is whichever is earlier between the date they were created or the earliest date the habit was completed on.")
                    
                }
                
                Section("Your habits' start dates") {
                    ForEach(habits) { habit in
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
    InfoSheet()
        .modelContainer(for: Habit.self, inMemory: true) { result in
            if case .success(let container) = result {
                Habit.sampleData.forEach { habit in
                    container.mainContext.insert(habit)
                }
            }
        }
        .environmentObject(ViewModel())
}
