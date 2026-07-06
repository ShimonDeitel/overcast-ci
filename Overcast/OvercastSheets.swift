import SwiftUI

/// One unified sheet enum for the whole app — a single `.sheet(item:)` per
/// screen, per the standing rule.
enum OvercastSheet: Identifiable {
    case add
    case edit(MoodEntry)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let e): return "edit-\(e.id)"
        case .paywall: return "paywall"
        }
    }
}

struct EntryFormView: View {
    @EnvironmentObject private var store: OvercastStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: MoodEntry?

    @State private var date: Date
    @State private var weather: WeatherCondition
    @State private var mood: Int
    @State private var note: String

    init(existing: MoodEntry?) {
        self.existing = existing
        _date = State(initialValue: existing?.date ?? Date())
        _weather = State(initialValue: existing?.weather ?? .sunny)
        _mood = State(initialValue: existing?.mood ?? 3)
        _note = State(initialValue: existing?.note ?? "")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("dateField")
                }

                Section("Weather") {
                    Picker("Condition", selection: $weather) {
                        ForEach(WeatherCondition.allCases) { condition in
                            Label(condition.rawValue, systemImage: condition.symbolName)
                                .tag(condition)
                        }
                    }
                    .accessibilityIdentifier("weatherPicker")
                }

                Section("Mood") {
                    VStack(alignment: .leading, spacing: 10) {
                        SkyMoodSlider(mood: $mood)
                            .frame(height: 64)
                        HStack {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    mood = value
                                } label: {
                                    Text("\(value)")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(mood == value ? OCTheme.skyColor(forMood: value) : OCTheme.surfaceRaised)
                                        .foregroundStyle(mood == value ? Color.white : OCTheme.ink)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("moodButton_\(value)")
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything notable today (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                        .accessibilityIdentifier("noteField")
                }

                if isEditing {
                    Section {
                        Button("Delete Entry", role: .destructive) {
                            if let existing {
                                store.deleteEntry(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteEntryButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("saveEntryButton")
                }
            }
        }
    }

    private func save() {
        if let existing {
            store.updateEntry(existing.id, date: date, weather: weather, mood: mood, note: note)
            dismiss()
        } else {
            guard store.canAddEntry(isPro: purchases.isPro) else { return }
            store.addEntry(date: date, weather: weather, mood: mood, note: note, isPro: purchases.isPro)
            dismiss()
        }
    }
}

/// The quirky signature feature: a literal "sky" bar that visually clears
/// from overcast slate-grey to bright sunbeam-yellow as the user drags to
/// set their mood — the sky brightens in real time as mood improves.
struct SkyMoodSlider: View {
    @Binding var mood: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(OCTheme.skyColor(forMood: mood))
                    .animation(.easeInOut(duration: 0.3), value: mood)

                HStack {
                    Image(systemName: mood >= 4 ? "sun.max.fill" : mood <= 2 ? "cloud.rain.fill" : "cloud.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.leading, 16)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = max(0, min(1, value.location.x / geo.size.width))
                        mood = 1 + Int((ratio * 4).rounded())
                    }
            )
        }
    }
}
