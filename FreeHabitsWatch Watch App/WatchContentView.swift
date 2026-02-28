//
//  WatchContentView.swift
//  FreeHabitsWatch Watch App
//
//  Created by Jonas Gunklach on 28.04.26.
//

import SwiftUI
import SwiftData

struct WatchContentView: View {
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]

    private var todayHabits: [Habit] {
        allHabits.filter { !$0.isArchived && $0.isDueToday }
    }

    private var completedCount: Int {
        todayHabits.filter(\.isCompletedToday).count
    }

    var body: some View {
        NavigationStack {
            if todayHabits.isEmpty {
                emptyState
            } else {
                habitList
            }
        }
    }

    // MARK: - Habit list

    private var habitList: some View {
        List {
            // Progress header
            Section {
                WatchProgressRow(completed: completedCount, total: todayHabits.count)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 4, trailing: 0))
            }

            // Habit rows
            ForEach(todayHabits) { habit in
                WatchHabitRowView(habit: habit)
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Today")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("No habits\ndue today")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Today")
    }
}

// MARK: - Progress row

private struct WatchProgressRow: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }

    private var allDone: Bool { completed == total }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(allDone ? "All done! 🎉" : "\(completed) of \(total)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(allDone ? .green : .primary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(allDone ? .green : .blue)
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }
}
