//
//  WatchHabitRowView.swift
//  FreeHabitsWatch
//

import SwiftUI
import SwiftData

struct WatchHabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit

    /// Drives the pop-scale burst on toggle.
    @State private var isBouncing = false

    private var isCompleted: Bool { habit.isCompletedToday }

    var body: some View {
        Button(action: toggleCompletion) {
            HStack(spacing: 10) {
                iconCircle
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 14, weight: isCompleted ? .regular : .medium))
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCompleted
                      ? habit.habitColor.opacity(0.18)
                      : Color.primary.opacity(0.07))
                .animation(.easeInOut(duration: 0.25), value: isCompleted)
        )
        .sensoryFeedback(.impact(weight: .light), trigger: isCompleted)
    }

    // MARK: - Icon circle

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(habit.habitColor.opacity(isCompleted ? 1.0 : 0.28))
                // Pop-scale burst when completing
                .scaleEffect(isBouncing ? 1.25 : 1.0)
                .animation(
                    .spring(response: 0.2, dampingFraction: 0.4),
                    value: isBouncing
                )

            Group {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.3)
                                    .combined(with: .opacity),
                                removal: .scale(scale: 0.3)
                                    .combined(with: .opacity)
                            )
                        )
                } else {
                    Image(systemName: habit.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.3)
                                    .combined(with: .opacity),
                                removal: .scale(scale: 0.3)
                                    .combined(with: .opacity)
                            )
                        )
                }
            }
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: isCompleted
            )
        }
    }

    // MARK: - Toggle

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            let cal = Calendar.current
            let today = Date.now

            if isCompleted {
                (habit.completions ?? [])
                    .filter { cal.isDate($0.date, inSameDayAs: today) }
                    .forEach { modelContext.delete($0) }
            } else {
                if habit.completions == nil { habit.completions = [] }
                habit.completions!.append(HabitCompletion(date: today))

                // Brief pop-scale burst
                isBouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    isBouncing = false
                }
            }
        }
    }
}
