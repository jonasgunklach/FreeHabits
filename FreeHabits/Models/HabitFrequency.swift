//
//  HabitFrequency.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import Foundation

/// Describes how often a habit should be performed.
enum HabitFrequency: Codable, Hashable {
    /// Every day.
    case daily
    /// Specific weekdays (1 = Sunday … 7 = Saturday, matching Calendar.weekday).
    case weekdays([Int])
    /// A fixed number of times per week (any days).
    case timesPerWeek(Int)

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case type, weekdays, count
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .daily:
            try c.encode("daily", forKey: .type)
        case .weekdays(let days):
            try c.encode("weekdays", forKey: .type)
            try c.encode(days, forKey: .weekdays)
        case .timesPerWeek(let n):
            try c.encode("timesPerWeek", forKey: .type)
            try c.encode(n, forKey: .count)
        }
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type_ = try c.decode(String.self, forKey: .type)
        switch type_ {
        case "weekdays":
            let days = try c.decode([Int].self, forKey: .weekdays)
            self = .weekdays(days)
        case "timesPerWeek":
            let n = try c.decode(Int.self, forKey: .count)
            self = .timesPerWeek(n)
        default:
            self = .daily
        }
    }

    // MARK: Helpers

    var displayName: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays(let days):
            if days.sorted() == [2, 3, 4, 5, 6] { return "Weekdays" }
            if days.sorted() == [1, 7] { return "Weekends" }
            let syms = Calendar.current.shortWeekdaySymbols
            let names = days.sorted().compactMap { syms[safe: $0 - 1] }.joined(separator: ", ")
            return names
        case .timesPerWeek(let n):
            return "\(n)× per week"
        }
    }

    /// Returns true if the habit is due on the given date according to this frequency.
    func isDue(on date: Date) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekdays(let days):
            let weekday = Calendar.current.component(.weekday, from: date)
            return days.contains(weekday)
        case .timesPerWeek:
            // Always "due" — the count is evaluated at the week level
            return true
        }
    }

    /// For timesPerWeek: returns true if the habit has been completed enough times this week.
    func isCompletedForWeek(completions: [Date], relativeTo date: Date = .now) -> Bool {
        guard case .timesPerWeek(let target) = self else { return false }
        let cal = Calendar.current
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: date) else { return false }
        let count = completions.filter { weekInterval.contains($0) }.count
        return count >= target
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
