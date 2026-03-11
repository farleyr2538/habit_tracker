//
//  Habit_Tracker_WidgetBundle.swift
//  Habit Tracker Widget
//
//  Created by Rob Farley on 03/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct Habit_Tracker_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Habit_Tracker_Widget()
        // Temporarily removed Control Widget and Live Activity
        // Add them back later if needed:
        // Habit_Tracker_WidgetControl()
        // Habit_Tracker_WidgetLiveActivity()
    }
}
