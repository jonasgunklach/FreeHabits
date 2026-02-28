//
//  FreeHabitsWatchApp.swift
//  FreeHabitsWatch Watch App
//
//  Created by Jonas Gunklach on 28.04.26.
//

import SwiftUI
import SwiftData

@main
struct FreeHabitsWatchApp: App {

    /// Uses the same CloudKit private container as the iOS app so data syncs automatically.
    var sharedModelContainer: ModelContainer = {
        let config = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.de.jonasgunklach.FreeHabits")
        )
        do {
            return try ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
