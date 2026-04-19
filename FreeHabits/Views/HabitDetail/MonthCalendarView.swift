//
//  MonthCalendarView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI

struct MonthCalendarView: View {
    let habit: Habit

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        // Leading empty cells to align the first day with the correct weekday
        let firstWeekday = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return cells
    }

    private var completedDays: Set<Date> {
        Set(habit.completions.map { calendar.startOfDay(for: $0.date) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(displayedMonth <= calendar.startOfMonth(for: habit.createdAt))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(displayedMonth >= calendar.startOfMonth(for: .now))
            }

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    if let day = days[i] {
                        let completed = completedDays.contains(calendar.startOfDay(for: day))
                        let isToday = calendar.isDateInToday(day)
                        let isFuture = day > .now

                        ZStack {
                            Circle()
                                .fill(completed ? habit.habitColor : Color.clear)
                            if isToday && !completed {
                                Circle()
                                    .stroke(habit.habitColor, lineWidth: 1.5)
                            }
                            Text("\(calendar.component(.day, from: day))")
                                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                                .foregroundStyle(
                                    completed ? .white :
                                    isFuture ? Color(.quaternaryLabel) :
                                    isToday ? habit.habitColor : Color(.label)
                                )
                        }
                        .frame(height: 34)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var weekdaySymbols: [String] {
        var syms = calendar.veryShortWeekdaySymbols
        // Rotate to match firstWeekday
        let offset = (calendar.firstWeekday - 1 + syms.count) % syms.count
        return Array(syms[offset...] + syms[..<offset])
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
