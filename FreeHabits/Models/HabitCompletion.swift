//
//  HabitCompletion.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var date: Date = Date.now
    var habit: Habit?

    init(date: Date = .now) {
        self.date = date
    }
}
