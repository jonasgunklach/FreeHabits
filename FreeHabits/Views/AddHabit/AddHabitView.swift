//
//  AddHabitView.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// When non-nil we're editing an existing habit; otherwise creating a new one.
    var editingHabit: Habit? = nil

    @State private var habitName = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    @State private var selectedFrequency: HabitFrequency = .daily
    @State private var reminderEnabled = false
    @State private var reminderDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @FocusState private var isNameFocused: Bool

    private let icons: [String] = [
        "figure.walk", "figure.run", "dumbbell.fill", "bicycle", "sportscourt.fill", "figure.cooldown",
        "book.fill", "pencil", "brain.head.profile", "graduationcap.fill", "lightbulb.fill", "doc.text.fill",
        "drop.fill", "cup.and.saucer.fill", "fork.knife", "carrot.fill", "leaf.fill", "pills.fill",
        "moon.fill", "sun.max.fill", "sunrise.fill", "bed.double.fill", "alarm.fill", "shower.fill",
        "heart.fill", "lungs.fill", "figure.mind.and.body", "cross.fill", "bandage.fill", "stethoscope",
        "music.note", "paintbrush.fill", "camera.fill", "guitars.fill", "mic.fill", "theatermasks.fill",
        "flame.fill", "bolt.fill", "star.fill", "trophy.fill", "hands.sparkles.fill", "checkmark.seal.fill"
    ]

    private let colors: [(name: String, color: Color)] = [
        ("red", .red), ("orange", .orange), ("yellow", .yellow),
        ("green", .green), ("mint", .mint), ("teal", .teal),
        ("cyan", .cyan), ("blue", .blue), ("indigo", .indigo),
        ("purple", .purple), ("pink", .pink)
    ]

    private var isEditing: Bool { editingHabit != nil }
    private var title: String { isEditing ? "Edit Habit" : "New Habit" }
    private var actionLabel: String { isEditing ? "Save" : "Add" }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                Section("Name") {
                    TextField("e.g. Morning Run", text: $habitName)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
                }
                frequencySection
                reminderSection
                colorSection
                iconSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(actionLabel) { save() }
                        .fontWeight(.semibold)
                        .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let h = editingHabit {
                    habitName = h.name
                    selectedIcon = h.icon
                    selectedColor = h.colorName
                    selectedFrequency = h.frequency
                    if let t = h.reminderTime {
                        reminderEnabled = true
                        let cal = Calendar.current
                        let base = cal.startOfDay(for: .now)
                        reminderDate = base.addingTimeInterval(t)
                    }
                } else {
                    isNameFocused = true
                }
            }
        }
    }

    // MARK: - Sections

    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.fromHabitColorName(selectedColor).gradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIcon)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                    Text(habitName.isEmpty ? "New Habit" : habitName)
                        .font(.headline)
                        .foregroundStyle(habitName.isEmpty ? .secondary : .primary)
                        .animation(.default, value: habitName)
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .listRowBackground(Color.clear)
    }

    private var frequencySection: some View {
        Section("Frequency") {
            Picker("Frequency", selection: frequencyBinding) {
                Text("Every day").tag(FrequencyOption.daily)
                Text("Weekdays").tag(FrequencyOption.weekdays)
                Text("Weekends").tag(FrequencyOption.weekends)
                Text("2× per week").tag(FrequencyOption.twice)
                Text("3× per week").tag(FrequencyOption.thrice)
                Text("5× per week").tag(FrequencyOption.five)
            }
            .pickerStyle(.menu)
        }
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Toggle("Daily Reminder", isOn: $reminderEnabled)
            if reminderEnabled {
                DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 11), spacing: 10) {
                ForEach(colors, id: \.name) { item in
                    Circle()
                        .fill(item.color)
                        .frame(height: 30)
                        .overlay {
                            if selectedColor == item.name {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .scaleEffect(selectedColor == item.name ? 1.15 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedColor)
                        .onTapGesture { selectedColor = item.name }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(icons, id: \.self) { icon in
                    let isSelected = selectedIcon == icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected
                                  ? Color.fromHabitColorName(selectedColor)
                                  : Color(.tertiarySystemFill))
                            .frame(height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isSelected ? .white : Color(.label))
                    }
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedIcon)
                    .onTapGesture { selectedIcon = icon }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Frequency binding helper

    private enum FrequencyOption: Hashable {
        case daily, weekdays, weekends, twice, thrice, five
    }

    private var frequencyBinding: Binding<FrequencyOption> {
        Binding(
            get: {
                switch selectedFrequency {
                case .daily: return .daily
                case .weekdays(let d) where d.sorted() == [1, 7]: return .weekends
                case .weekdays: return .weekdays
                case .timesPerWeek(let n):
                    switch n {
                    case 2: return .twice
                    case 3: return .thrice
                    case 5: return .five
                    default: return .daily
                    }
                }
            },
            set: { option in
                switch option {
                case .daily:    selectedFrequency = .daily
                case .weekdays: selectedFrequency = .weekdays([2, 3, 4, 5, 6])
                case .weekends: selectedFrequency = .weekdays([1, 7])
                case .twice:    selectedFrequency = .timesPerWeek(2)
                case .thrice:   selectedFrequency = .timesPerWeek(3)
                case .five:     selectedFrequency = .timesPerWeek(5)
                }
            }
        )
    }

    // MARK: - Save

    private func save() {
        let trimmed = habitName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let reminderTimeValue: TimeInterval? = reminderEnabled
            ? timeOfDaySeconds(from: reminderDate)
            : nil

        if let habit = editingHabit {
            habit.name = trimmed
            habit.icon = selectedIcon
            habit.colorName = selectedColor
            habit.frequency = selectedFrequency
            habit.reminderTime = reminderTimeValue
            NotificationManager.shared.scheduleReminder(for: habit)
        } else {
            let habit = Habit(name: trimmed, icon: selectedIcon, colorName: selectedColor)
            habit.frequency = selectedFrequency
            habit.reminderTime = reminderTimeValue
            modelContext.insert(habit)
            NotificationManager.shared.scheduleReminder(for: habit)
        }
        dismiss()
    }

    private func timeOfDaySeconds(from date: Date) -> TimeInterval {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return TimeInterval(h * 3600 + m * 60)
    }
}
