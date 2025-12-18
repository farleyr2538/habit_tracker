//
//  Calendar.swift
//  Practice
//
//  Created by Robert Farley on 14/05/2025.
//

import SwiftUI
import Foundation

// data structure:

// each habit is a database of dates on which that habit was practiced

// calendar needs to display a bunch of dates in a weekly/monthly format for the user to select

// but what I need is a set or array of Dates, so that when one is pressed, it knows which date to add to a Habit's database
// or I could use index, but that seems messy. how would it work?
// for each button, if pressed, get index, and find the day with that index in relation to first day

// alternative: if we can have an array of dates for the period in question, then it is just a matter of 'on press, add self.date to current habit's database'
