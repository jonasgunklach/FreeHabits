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
            VStack(spacing: 16) {
                heroCard
                statsRow
                    .padding(.horizontal, 20)
                completionRateCard
                    .padding(.horizontal, 20)
                weekCard
                    .padding(.horizontal, 20)
                MonthCalendarView(habit: habit)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddHabitView(editingHabit: habit)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background
            habit.habitColor

            // Large watermark icon — decorative, bottom-trailing
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: habit.icon)
                        .font(.system(size: 160, weight: .black))
                        .foregroundStyle(.white.opacity(0.1))
                        .offset(x: 24, y: 24)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.22))
                        .frame(width: 60, height: 60)
                    Image(systemName: habit.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .symbolEffect(.bounce, value: habit.isCompletedToday)

                // Name + frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(habit.frequency.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }

                // Badges
                HStack(spacing: 10) {
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if habit.isCompletedToday {
                        Label("Done today", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: habit.isCompletedToday)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: habit.habitColor.opacity(0.32), radius: 18, y: 6)
        .padding(.horizontal, 20)
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
        let color = rateColor(rate)
        let completedDays = Int(rate * 30)

        return HStack(spacing: 20) {
            // Donut ring with % inside
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: rate)
                VStack(spacing: 1) {
                    Text("\(pct)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                Text("30-DAY RATE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(rateLabel(rate))
                    .font(.title3.bold())
                    .foregroundStyle(color)
                Text("\(completedDays) of 30 days completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    let completed = (habit.completions ?? []).contains {
                        calendar.isDate($0.date, inSameDayAs: day)
                    }
                    let isToday = calendar.isDateInToday(day)

                    VStack(spacing: 5) {
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? habit.habitColor : .secondary)

                        ZStack {
                            Circle()
                                .fill(completed ? habit.habitColor : Color(.systemFill))
                                .frame(width: 38, height: 38)
                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: completed ? habit.habitColor.opacity(0.35) : .clear, radius: 4, y: 2)
                        .overlay {
                            if isToday {
                                Circle()
                                    .stroke(habit.habitColor, lineWidth: 2.5)
                                    .frame(width: 38, height: 38)
                            }
                        }

                        Text(day, format: .dateTime.day())
                            .font(.caption2.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? habit.habitColor : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
