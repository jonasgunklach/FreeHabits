//
//  HabitRowView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI
import SwiftData

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit
    var date: Date = Calendar.current.startOfDay(for: .now)

    private var isCompleted: Bool {
        habit.isCompleted(on: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            habitIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(habit.currentStreak == 1 ? "1 day streak" : "\(habit.currentStreak) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button {
                toggleCompletion()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(isCompleted ? habit.habitColor : Color(.tertiaryLabel))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.impact(weight: .light), trigger: isCompleted)
    }

    private var habitIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(habit.habitColor.gradient)
                .frame(width: 44, height: 44)
            Image(systemName: habit.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            let cal = Calendar.current
            if isCompleted {
                habit.completions
                    .filter { cal.isDate($0.date, inSameDayAs: date) }
                    .forEach { modelContext.delete($0) }
            } else {
                habit.completions.append(HabitCompletion(date: date))
            }
        }
    }
}
