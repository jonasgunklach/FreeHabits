//
//  NotificationManager.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import UserNotifications
import Foundation
import SwiftData

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: Permission

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: Schedule

    /// Schedules (or reschedules) a daily reminder for a habit at the given time-of-day offset.
    func scheduleReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else {
            removeReminder(for: habit)
            return
        }

        let center = UNUserNotificationCenter.current()
        let identifier = notificationID(for: habit)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "Time to build your habit 💪"
        content.sound = .default

        let totalSeconds = Int(reminderTime)
        var components = DateComponents()
        components.hour = totalSeconds / 3600
        components.minute = (totalSeconds % 3600) / 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)

        center.add(request) { _ in }
    }

    func removeReminder(for habit: Habit) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: habit)])
    }

    // MARK: Evening nudge

    /// Schedules a one-off evening notification if not all habits are done.
    /// Should be called after the user dismisses a completion to re-evaluate.
    func scheduleEveningNudge(pendingCount: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "evening_nudge"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard pendingCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break the streak!"
        content.body = pendingCount == 1
            ? "1 habit left for today."
            : "\(pendingCount) habits left for today."
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: Private

    private func notificationID(for habit: Habit) -> String {
        "habit_reminder_\(habit.persistentModelID)"
    }
}
