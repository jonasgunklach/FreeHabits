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
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? habit.habitColor.gradient : habit.habitColor.opacity(0.15).gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: habit.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isCompleted ? .white : habit.habitColor)
                }

                VStack(spacing: 2) {
                    Text(habit.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if habit.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isCompleted
                          ? habit.habitColor.opacity(0.12)
                          : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isCompleted ? habit.habitColor.opacity(0.3) : .clear, lineWidth: 1.5)
                    )
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isCompleted)
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
