import Foundation

@MainActor
final class OvercastStore: ObservableObject {
    @Published private(set) var entries: [MoodEntry] = []

    private let freeLimit = 7
    private let fileURL: URL

    init(fileName: String = "overcast_entries.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent(fileName)
        load()
    }

    var sortedEntries: [MoodEntry] {
        entries.sorted { $0.date > $1.date }
    }

    func canAddEntry(isPro: Bool) -> Bool {
        isPro || entries.count < freeLimit
    }

    @discardableResult
    func addEntry(date: Date, weather: WeatherCondition, mood: Int, note: String, isPro: Bool) -> Bool {
        guard canAddEntry(isPro: isPro) else { return false }
        let entry = MoodEntry(date: date, weather: weather, mood: mood, note: note)
        entries.append(entry)
        save()
        return true
    }

    func updateEntry(_ id: UUID, date: Date, weather: WeatherCondition, mood: Int, note: String) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].date = date
        entries[idx].weather = weather
        entries[idx].mood = mood
        entries[idx].note = note
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func deleteAllData() {
        entries.removeAll()
        save()
    }

    /// The signature feature: computes each weather condition's average
    /// logged mood across the user's own history, so they can see whether
    /// (for THEM) rain really does correlate with a lower mood, etc.
    var correlationStats: [WeatherMoodStat] {
        WeatherCondition.allCases.compactMap { condition in
            let matching = entries.filter { $0.weather == condition }
            guard !matching.isEmpty else { return nil }
            let avg = Double(matching.reduce(0) { $0 + $1.mood }) / Double(matching.count)
            return WeatherMoodStat(weather: condition, averageMood: avg, entryCount: matching.count)
        }.sorted { $0.averageMood > $1.averageMood }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
