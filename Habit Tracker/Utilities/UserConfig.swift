//
//  UserConfig.swift
//  Practice
//
//  Created by Robert Farley on 22/12/2025.
//

import Foundation

struct UserConfig {
    var isFirstTime : Bool = true
    var setupDate : Date = Date()
    var daysSinceSetup : Int = 0
    var daysLastMonth : Int = 0
    var monthBeforeSetup : Date = Date()
}
