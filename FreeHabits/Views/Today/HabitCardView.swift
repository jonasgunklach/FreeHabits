//
//  HabitCardView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 19.04.26.
//

import SwiftUI
import SwiftData

struct HabitCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit
    var date: Date = Calendar.current.startOfDay(for: .now)

    private var isCompleted: Bool {
        habit.isCompleted(on: date)
    }

    var body: some View {
        Button {
            toggleCompletion()
        } label: {
            VStack(spacing: 0) {
                // Colored top half — icon lives here
                ZStack {
                    habit.habitColor
                        .opacity(isCompleted ? 1.0 : 0.82)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: habit.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 76)

                // White/grouped bottom — name + streak
                VStack(spacing: 4) {
                    Text(habit.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(habit.currentStreak > 0 ? .orange : Color(.quaternaryLabel))
                        Text(habit.currentStreak > 0 ? "\(habit.currentStreak)" : "—")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: habit.habitColor.opacity(isCompleted ? 0.35 : 0.18), radius: isCompleted ? 8 : 4, y: 2)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isCompleted)
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            let cal = Calendar.current
            if isCompleted {
                (habit.completions ?? [])
                    .filter { cal.isDate($0.date, inSameDayAs: date) }
                    .forEach { modelContext.delete($0) }
            } else {
                if habit.completions == nil { habit.completions = [] }
                habit.completions!.append(HabitCompletion(date: date))
            }
        }
    }
}
