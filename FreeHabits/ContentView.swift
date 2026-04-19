//
//  ContentView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var showingAddHabit = false
    @State private var habitToEdit: Habit? = nil
    @State private var showingArchive = false
    @AppStorage("useGridView") private var useGridView = true

    private let calendar = Calendar.current
    private var today: Date { calendar.startOfDay(for: .now) }
    private var isToday: Bool { selectedDate == today }

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    private var archivedHabits: [Habit] { habits.filter(\.isArchived) }

    private var completedOnDate: Int {
        activeHabits.filter { $0.isCompleted(on: selectedDate) }.count
    }
    private var dueOnDate: Int {
        activeHabits.filter { $0.frequency.isDue(on: selectedDate) }.count
    }

    private var navigationTitle: String {
        if isToday { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeHabits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $habitToEdit) { habit in
                AddHabitView(editingHabit: habit)
            }
            .sheet(isPresented: $showingArchive) {
                ArchivedHabitsView(habits: archivedHabits)
            }
        }
        // Horizontal swipe to navigate days.
        // simultaneousGesture so list scroll and row swipe actions still work.
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    // Only act on clearly horizontal swipes
                    guard abs(h) > abs(v) * 1.5, abs(h) > 40 else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if h < 0 {
                            // Swipe left → go forward (toward today)
                            guard selectedDate < today,
                                  let next = calendar.date(byAdding: .day, value: 1, to: selectedDate)
                            else { return }
                            selectedDate = min(next, today)
                        } else {
                            // Swipe right → go back (older)
                            guard let prev = calendar.date(byAdding: .day, value: -1, to: selectedDate)
                            else { return }
                            selectedDate = prev
                        }
                    }
                }
        )
        .onChange(of: activeHabits.count) {
            let pending = activeHabits.filter { !$0.isCompletedToday && $0.isDueToday }.count
            NotificationManager.shared.scheduleEveningNudge(pendingCount: pending)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        useGridView.toggle()
                    }
                } label: {
                    Image(systemName: useGridView ? "list.bullet" : "square.grid.2x2")
                        .contentTransition(.symbolEffect(.replace))
                }

                Button {
                    showingAddHabit = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }

        if !isToday {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = today
                    }
                } label: {
                    Label("Today", systemImage: "calendar.badge.clock")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.medium))
                }
            }
        } else if !activeHabits.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    EditButton()
                    if !archivedHabits.isEmpty {
                        Button {
                            showingArchive = true
                        } label: {
                            Label("Archived Habits", systemImage: "archivebox")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Habit Content

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var habitList: some View {
        Group {
            if useGridView {
                habitGrid
            } else {
                habitListView
            }
        }
    }

    private var habitGrid: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressHeaderView(
                    completed: completedOnDate,
                    total: dueOnDate,
                    date: selectedDate
                )
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(activeHabits) { habit in
                        NavigationLink {
                            HabitDetailView(habit: habit)
                        } label: {
                            HabitCardView(habit: habit, date: selectedDate)
                        }
                        .contextMenu {
                            Button {
                                habitToEdit = habit
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                withAnimation { habit.archivedAt = .now }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }

    private var habitListView: some View {
        List {
            Section {
                ProgressHeaderView(
                    completed: completedOnDate,
                    total: dueOnDate,
                    date: selectedDate
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
            }

            Section("My Habits") {
                ForEach(activeHabits) { habit in
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        HabitRowView(habit: habit, date: selectedDate)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            habitToEdit = habit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            withAnimation { habit.archivedAt = .now }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
                .onMove { from, to in
                    var reordered = activeHabits
                    reordered.move(fromOffsets: from, toOffset: to)
                    for (i, habit) in reordered.enumerated() {
                        habit.sortOrder = i
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 72))
                .foregroundStyle(.quaternary)
            VStack(spacing: 8) {
                Text("No Habits Yet")
                    .font(.title2.bold())
                Text("Tap + to add your first habit\nand start building a better routine.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showingAddHabit = true
            } label: {
                Label("Add Habit", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Archived Habits

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(habit.habitColor.opacity(0.3))
                                .frame(width: 44, height: 44)
                            Image(systemName: habit.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(habit.habitColor)
                        }
                        Text(habit.name)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            withAnimation { habit.archivedAt = nil }
                        } label: {
                            Label("Unarchive", systemImage: "arrow.uturn.up")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            modelContext.delete(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Archived")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView("No Archived Habits", systemImage: "archivebox")
                }
            }
        }
    }
}
