//
//  HabitDetailView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false

    private let calendar = Calendar.current

    private var last7Days: [Date] {
        (0..<7).compactMap { i in
            calendar.date(byAdding: .day, value: -(6 - i), to: calendar.startOfDay(for: .now))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                statsRow
                    .padding(.horizontal)
                completionRateCard
                    .padding(.horizontal)
                weekCard
                    .padding(.horizontal)
                MonthCalendarView(habit: habit)
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddHabitView(editingHabit: habit)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(habit.habitColor.gradient)
            VStack(spacing: 14) {
                Image(systemName: habit.icon)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: habit.isCompletedToday)
                Text(habit.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(habit.frequency.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                if habit.isCompletedToday {
                    Label("Completed today", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 36)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: habit.isCompletedToday)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Streak",
                value: "\(habit.currentStreak)",
                unit: habit.currentStreak == 1 ? "day" : "days",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Best",
                value: "\(habit.bestStreak)",
                unit: habit.bestStreak == 1 ? "day" : "days",
                icon: "trophy.fill",
                color: .yellow
            )
            StatCard(
                title: "Total",
                value: "\(habit.totalCompletions)",
                unit: habit.totalCompletions == 1 ? "day" : "days",
                icon: "checkmark.seal.fill",
                color: habit.habitColor
            )
        }
    }

    // MARK: - Completion rate card

    private var completionRateCard: some View {
        let rate = habit.completionRate30Days
        let pct = Int(rate * 100)

        return VStack(alignment: .leading, spacing: 10) {
            Text("30-Day Completion Rate")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(pct)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(rateColor(rate))
                    Text(rateLabel(rate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: rate)
                        .stroke(rateColor(rate).gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: rate)
                }
                .frame(width: 64, height: 64)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func rateColor(_ rate: Double) -> Color {
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .orange }
        return .red
    }

    private func rateLabel(_ rate: Double) -> String {
        if rate >= 0.9 { return "Excellent" }
        if rate >= 0.7 { return "Great" }
        if rate >= 0.5 { return "Good" }
        if rate >= 0.3 { return "Needs work" }
        return "Just getting started"
    }

    // MARK: - Week card

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 7 Days")
                .font(.headline)

            HStack(spacing: 0) {
                ForEach(last7Days, id: \.self) { day in
                    let completed = habit.completions.contains {
                        calendar.isDate($0.date, inSameDayAs: day)
                    }
                    let isToday = calendar.isDateInToday(day)

                    VStack(spacing: 8) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? habit.habitColor : .secondary)

                        ZStack {
                            Circle()
                                .fill(completed ? habit.habitColor : Color(.systemFill))
                                .frame(width: 36, height: 36)
                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            if isToday {
                                Circle()
                                    .stroke(habit.habitColor, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
