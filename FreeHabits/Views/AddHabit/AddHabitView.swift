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
    @State private var healthLinkEnabled = false
    @State private var selectedHealthLink: String? = nil
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
    private var actionLabel: String { isEditing ? "Save Changes" : "Add Habit" }
    private var accentColor: Color { Color.fromHabitColorName(selectedColor) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    livePreview
                    nameCard
                    styleCard
                    frequencyCard
                    reminderCard
                    if HealthKitManager.isAvailable {
                        healthLinkCard
                    }
                    addButton
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let h = editingHabit {
                    habitName = h.name
                    selectedIcon = h.icon
                    selectedColor = h.colorName
                    selectedFrequency = h.frequency
                    if let hkId = h.healthKitIdentifier {
                        healthLinkEnabled = true
                        selectedHealthLink = hkId
                    }
                    if let t = h.reminderTime {
                        reminderEnabled = true
                        let cal = Calendar.current
                        let base = cal.startOfDay(for: .now)
                        reminderDate = base.addingTimeInterval(t)
                    }
                }
            }
        }
    }

    // MARK: - Live Preview

    private var livePreview: some View {
        VStack(spacing: 0) {
            ZStack {
                accentColor
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
                Image(systemName: selectedIcon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIcon)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            VStack(spacing: 6) {
                Text(habitName.isEmpty ? "Your Habit" : habitName)
                    .font(.title3.bold())
                    .foregroundStyle(habitName.isEmpty ? .secondary : .primary)
                    .animation(.default, value: habitName)
                Text(currentFrequencyOption.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: accentColor.opacity(0.28), radius: 14, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedColor)
    }

    // MARK: - Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Name", systemImage: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            TextField("e.g. Morning Run", text: $habitName)
                .focused($isNameFocused)
                .font(.title3.weight(.medium))
                .submitLabel(.done)
                .onSubmit { isNameFocused = false }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Style (Color + Icon)

    private var styleCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Style", systemImage: "paintpalette.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                // Horizontal color strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.name) { item in
                            ZStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 38, height: 38)
                                if selectedColor == item.name {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2.5)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .shadow(color: item.color.opacity(selectedColor == item.name ? 0.55 : 0), radius: 5, y: 2)
                            .scaleEffect(selectedColor == item.name ? 1.18 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: selectedColor)
                            .onTapGesture { selectedColor = item.name }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Icon grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                    spacing: 8
                ) {
                    ForEach(icons, id: \.self) { icon in
                        let isSelected = selectedIcon == icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? accentColor : Color(.tertiarySystemFill))
                                .frame(height: 44)
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(isSelected ? .white : Color(.label))
                        }
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedIcon)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedColor)
                        .onTapGesture { selectedIcon = icon }
                    }
                }
                .padding(16)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Frequency

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Frequency", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FrequencyOption.allCases, id: \.self) { option in
                        let isSelected = currentFrequencyOption == option
                        Button {
                            setFrequency(option)
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(option.label)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background(isSelected ? accentColor : Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedFrequency)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedColor)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Reminder

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Reminder", systemImage: "bell")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    Text("Daily Reminder")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if reminderEnabled {
                    Divider().padding(.horizontal, 16)
                    DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3), value: reminderEnabled)
        }
    }

    // MARK: - Apple Health Link

    private var healthLinkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Apple Health", systemImage: "heart.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.pink.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.pink)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-track from Health")
                            .font(.subheadline.weight(.medium))
                        Text("Marks complete when logged in Apple Health")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $healthLinkEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if healthLinkEnabled {
                    Divider().padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(HealthKitManager.options) { option in
                                let isSelected = selectedHealthLink == option.id
                                Button {
                                    selectedHealthLink = option.id
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: option.sfSymbol)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(option.title)
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .background(isSelected ? accentColor : Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                                    .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedHealthLink)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    if selectedHealthLink == nil {
                        Text("Select a Health activity above")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.spring(response: 0.3), value: healthLinkEnabled)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        let isEmpty = habitName.trimmingCharacters(in: .whitespaces).isEmpty
        return Button(action: save) {
            Text(actionLabel)
                .font(.headline)
                .foregroundStyle(isEmpty ? Color(.tertiaryLabel) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(isEmpty ? Color(.systemFill) : accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: isEmpty ? .clear : accentColor.opacity(0.35), radius: 10, y: 4)
        }
        .disabled(isEmpty)
        .animation(.spring(response: 0.3), value: habitName.isEmpty)
        .animation(.spring(response: 0.3), value: selectedColor)
    }

    // MARK: - Frequency Helpers

    private enum FrequencyOption: Hashable, CaseIterable {
        case daily, twice, thrice, four, five, six

        var label: String {
            switch self {
            case .daily:  return "Every day"
            case .twice:  return "2×"
            case .thrice: return "3×"
            case .four:   return "4×"
            case .five:   return "5×"
            case .six:    return "6×"
            }
        }

        var icon: String {
            switch self {
            case .daily:  return "calendar"
            case .twice:  return "2.circle.fill"
            case .thrice: return "3.circle.fill"
            case .four:   return "4.circle.fill"
            case .five:   return "5.circle.fill"
            case .six:    return "6.circle.fill"
            }
        }
    }

    private var currentFrequencyOption: FrequencyOption {
        switch selectedFrequency {
        case .daily:
            return .daily
        case .weekdays:
            return .daily
        case .timesPerWeek(let n):
            switch n {
            case 2: return .twice
            case 3: return .thrice
            case 4: return .four
            case 5: return .five
            case 6: return .six
            default: return .daily
            }
        }
    }

    private func setFrequency(_ option: FrequencyOption) {
        switch option {
        case .daily:  selectedFrequency = .daily
        case .twice:  selectedFrequency = .timesPerWeek(2)
        case .thrice: selectedFrequency = .timesPerWeek(3)
        case .four:   selectedFrequency = .timesPerWeek(4)
        case .five:   selectedFrequency = .timesPerWeek(5)
        case .six:    selectedFrequency = .timesPerWeek(6)
        }
    }

    // MARK: - Save

    private func save() {
        let trimmed = habitName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let reminderTimeValue: TimeInterval? = reminderEnabled
            ? timeOfDaySeconds(from: reminderDate)
            : nil

        let hkId: String? = healthLinkEnabled ? selectedHealthLink : nil

        if let habit = editingHabit {
            habit.name = trimmed
            habit.icon = selectedIcon
            habit.colorName = selectedColor
            habit.frequency = selectedFrequency
            habit.reminderTime = reminderTimeValue
            habit.healthKitIdentifier = hkId
            NotificationManager.shared.scheduleReminder(for: habit)
        } else {
            let habit = Habit(name: trimmed, icon: selectedIcon, colorName: selectedColor)
            habit.frequency = selectedFrequency
            habit.reminderTime = reminderTimeValue
            habit.healthKitIdentifier = hkId
            modelContext.insert(habit)
            NotificationManager.shared.scheduleReminder(for: habit)
        }
        if healthLinkEnabled {
            Task { await HealthKitManager.shared.requestAuthorization() }
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
