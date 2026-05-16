//
//  HealthKitManager.swift
//  FreeHabits
//

import HealthKit
import SwiftData
import Foundation

/// Reads Apple Health data to auto-mark linked habits as complete.
/// All access is read-only — no data is ever written to HealthKit.
@MainActor
final class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    /// Whether HealthKit is available on this device (false on iPad without health data).
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Link options

    struct HealthLinkOption: Identifiable, Sendable {
        /// Stable identifier stored in `Habit.healthKitIdentifier`.
        let id: String
        let title: String
        let sfSymbol: String
    }

    static let options: [HealthLinkOption] = [
        .init(id: "workout.running",   title: "Running",           sfSymbol: "figure.run"),
        .init(id: "workout.walking",   title: "Walking",           sfSymbol: "figure.walk"),
        .init(id: "workout.cycling",   title: "Cycling",           sfSymbol: "bicycle"),
        .init(id: "workout.hiking",    title: "Hiking",            sfSymbol: "figure.hiking"),
        .init(id: "workout.swimming",  title: "Swimming",          sfSymbol: "figure.open.water.swim"),
        .init(id: "workout.yoga",      title: "Yoga",              sfSymbol: "figure.yoga"),
        .init(id: "workout.strength",  title: "Strength",          sfSymbol: "dumbbell.fill"),
        .init(id: "workout.hiit",      title: "HIIT",              sfSymbol: "bolt.fill"),
        .init(id: "mindfulSession",    title: "Meditation",        sfSymbol: "brain.head.profile"),
    ]

    // MARK: - Mapping identifiers → HK types

    private static let workoutTypeMap: [String: HKWorkoutActivityType] = [
        "workout.running":  .running,
        "workout.walking":  .walking,
        "workout.cycling":  .cycling,
        "workout.hiking":   .hiking,
        "workout.swimming": .swimming,
        "workout.yoga":     .yoga,
        "workout.strength": .traditionalStrengthTraining,
        "workout.hiit":     .highIntensityIntervalTraining,
    ]

    // MARK: - Authorization

    /// Requests read-only access for workout and mindfulness data.
    /// Safe to call multiple times — HealthKit silently skips already-decided types.
    func requestAuthorization() async {
        guard Self.isAvailable else { return }
        var readTypes: Set<HKObjectType> = [.workoutType()]
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            readTypes.insert(mindful)
        }
        _ = try? await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Querying

    /// Returns `true` when at least one sample matching `identifier` exists on `date`.
    func isActivityLogged(_ identifier: String, on date: Date) async -> Bool {
        guard Self.isAvailable else { return false }
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return false }
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        if identifier == "mindfulSession" {
            guard let sampleType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return false }
            return await hasSamples(of: sampleType, matching: datePredicate)
        }

        if let activityType = Self.workoutTypeMap[identifier] {
            let workoutPredicate = HKQuery.predicateForWorkouts(with: activityType)
            let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, workoutPredicate])
            return await hasSamples(of: .workoutType(), matching: compound)
        }

        return false
    }

    private func hasSamples(of type: HKSampleType, matching predicate: NSPredicate) async -> Bool {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: !(samples ?? []).isEmpty)
            }
            store.execute(query)
        }
    }

    // MARK: - Sync

    /// Checks today's Health data for every HealthKit-linked habit and inserts a
    /// `HabitCompletion` if the activity was recorded but not yet marked complete.
    /// Manual completions are never removed.
    func syncTodayCompletions(for habits: [Habit], context: ModelContext) async {
        guard Self.isAvailable else { return }
        let today = Date.now
        for habit in habits {
            guard let hkId = habit.healthKitIdentifier, !habit.isCompletedToday else { continue }
            guard await isActivityLogged(hkId, on: today) else { continue }
            if habit.completions == nil { habit.completions = [] }
            habit.completions!.append(HabitCompletion(date: today))
        }
        try? context.save()
    }
}
