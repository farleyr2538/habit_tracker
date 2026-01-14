//
//  PreviewContainer.swift
//  Practice
//
//  Created by Robert Farley on 20/05/2025.
//

import SwiftUI
import SwiftData

struct HabitSampleData : PreviewModifier {
    
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(for: Habit.self, configurations: .init(isStoredInMemoryOnly: true))
        Habit.sampleData.forEach { container.mainContext.insert($0) }
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
    
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var habitSampleData: Self = .modifier(HabitSampleData())
}
