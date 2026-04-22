//
//  CloudKitDebugExample.swift
//  Habit Tracker
//
//  Example of how to use the CloudKit Sync Debug function
//  Created on 18/04/2026
//

import SwiftUI
import SwiftData

struct CloudKitDebugExampleView: View {
    @Environment(ViewModel.self) var viewModel
    @Query var habits: [Habit]
    @Environment(\.modelContext) var context
    
    var body: some View {
        VStack(spacing: 20) {
            Text("CloudKit Debug Example")
                .font(.title)
            
            Text("\(habits.count) habits in database")
                .foregroundStyle(.secondary)
            
            Button {
                // Call the debug function
                viewModel.debugCloudKitSync(habits: habits, context: context)
            } label: {
                Label("Print Debug Report", systemImage: "icloud.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            
            Text("Check Xcode console for output")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    CloudKitDebugExampleView()
        .environment(ViewModel())
        .modelContainer(for: Habit.self, inMemory: true)
}
