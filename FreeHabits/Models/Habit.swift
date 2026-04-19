//
//  Habit.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var name: String = ""
    var icon: String = "star.fill"
    var colorName: String = "blue"
    var createdAt: Date = Date.now
    /// Manual sort position; lower = higher in list.
    var sortOrder: Int = 0
    /// Non-nil when the habit is archived.
    var archivedAt: Date?
    /// JSON-encoded HabitFrequency. Stored as Data so SwiftData can persist it.
    var frequencyData: Data?
    /// Time-of-day offset in seconds from midnight for the daily reminder. nil = no reminder.
    var reminderTime: TimeInterval?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, icon: String = "star.fill", colorName: String = "blue", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.createdAt = .now
        self.sortOrder = sortOrder
    }

    // MARK: Frequency helpers

    var frequency: HabitFrequency {
        get {
            guard let data = frequencyData,
                  let freq = try? JSONDecoder().decode(HabitFrequency.self, from: data)
            else { return .daily }
            return freq
        }
        set {
            frequencyData = try? JSONEncoder().encode(newValue)
        }
    }

    var isArchived: Bool { archivedAt != nil }

    var isCompletedToday: Bool {
        isCompleted(on: .now)
    }

    func isCompleted(on date: Date) -> Bool {
        let cal = Calendar.current
        return completions.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    var isDueToday: Bool {
        frequency.isDue(on: .now)
    }

    /// Completion rate over the last 30 days (only counting days the habit was due).
    var completionRate30Days: Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let completedDays = Set(completions.map { cal.startOfDay(for: $0.date) })
        var due = 0
        var done = 0
        for i in 0..<30 {
            guard let day = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            if frequency.isDue(on: day) {
                due += 1
                if completedDays.contains(day) { done += 1 }
            }
        }
        return due == 0 ? 0 : Double(done) / Double(due)
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let days = Set(completions.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard !days.isEmpty else { return 0 }

        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var checkDate: Date
        if days.contains(today) {
            checkDate = today
        } else if days.contains(yesterday) {
            checkDate = yesterday
        } else {
            return 0
        }

        var streak = 0
        for day in days {
            if day == checkDate {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                break
            }
        }
        return streak
    }

    var bestStreak: Int {
        let cal = Calendar.current
        let days = Set(completions.map { cal.startOfDay(for: $0.date) }).sorted()
        guard days.count > 0 else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<days.count {
            if let expected = cal.date(byAdding: .day, value: 1, to: days[i - 1]),
               expected == days[i] {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    var totalCompletions: Int {
        Set(completions.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var habitColor: Color {
        Color.fromHabitColorName(colorName)
    }
}
