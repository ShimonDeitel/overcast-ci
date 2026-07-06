import Foundation

enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case rainy = "Rainy"
    case stormy = "Stormy"
    case snowy = "Snowy"
    case foggy = "Foggy"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }
}

struct MoodEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weather: WeatherCondition
    var mood: Int          // 1...5
    var note: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weather: WeatherCondition,
        mood: Int,
        note: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.weather = weather
        self.mood = mood
        self.note = note
        self.createdDate = createdDate
    }
}

/// A single weather condition's aggregate correlation stats — the app's
/// core signature feature: does this user's mood actually correlate with
/// a given weather condition, based on their own logged history.
struct WeatherMoodStat: Identifiable {
    var id: String { weather.rawValue }
    let weather: WeatherCondition
    let averageMood: Double
    let entryCount: Int
}
