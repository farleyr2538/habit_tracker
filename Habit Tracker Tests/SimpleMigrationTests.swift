//
//  SimpleMigrationTests.swift
//  Habit Tracker Tests
//
//  Simple test to verify the test setup works
//

import XCTest
import SwiftData
import Foundation
@testable import Habit_Tracker

final class SimpleMigrationTests: XCTestCase {
    
    func testFrameworkWorks() async throws {
        XCTAssertTrue(true, "If you see this, test framework is configured correctly!")
        print("✅ Testing framework is working!")
    }
    
    @MainActor
    func testCalendarAccess() async throws {
        // This verifies we can access the calendar from your project
        let today = calendar.startOfDay(for: Date())
        XCTAssertLessThanOrEqual(today, Date(), "Start of day should be before or equal to now")
        print("✅ Can access project globals!")
    }
}
