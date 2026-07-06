import XCTest
@testable import Overcast

@MainActor
final class OvercastTests: XCTestCase {
    private func makeStore() -> OvercastStore {
        let name = "test_overcast_\(UUID().uuidString).json"
        return OvercastStore(fileName: name)
    }

    func testAddEntry() {
        let store = makeStore()
        let added = store.addEntry(date: Date(), weather: .sunny, mood: 5, note: "Great day", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.weather, .sunny)
        XCTAssertEqual(store.entries.first?.mood, 5)
    }

    func testFreeLimitBlocksAtSeven() {
        let store = makeStore()
        for i in 0..<7 {
            let added = store.addEntry(date: Date(), weather: .cloudy, mood: 3, note: "\(i)", isPro: false)
            XCTAssertTrue(added)
        }
        XCTAssertFalse(store.canAddEntry(isPro: false))
        let eighth = store.addEntry(date: Date(), weather: .cloudy, mood: 3, note: "eighth", isPro: false)
        XCTAssertFalse(eighth)
        XCTAssertEqual(store.entries.count, 7)
    }

    func testProBypassesFreeLimit() {
        let store = makeStore()
        for i in 0..<7 {
            _ = store.addEntry(date: Date(), weather: .cloudy, mood: 3, note: "\(i)", isPro: true)
        }
        XCTAssertTrue(store.canAddEntry(isPro: true))
        let added = store.addEntry(date: Date(), weather: .rainy, mood: 2, note: "eighth-pro", isPro: true)
        XCTAssertTrue(added)
        XCTAssertEqual(store.entries.count, 8)
    }

    func testUpdateEntry() {
        let store = makeStore()
        _ = store.addEntry(date: Date(), weather: .sunny, mood: 4, note: "orig", isPro: false)
        guard let id = store.entries.first?.id else { return XCTFail("no entry") }
        store.updateEntry(id, date: Date(), weather: .stormy, mood: 1, note: "updated")
        XCTAssertEqual(store.entries.first?.weather, .stormy)
        XCTAssertEqual(store.entries.first?.mood, 1)
        XCTAssertEqual(store.entries.first?.note, "updated")
    }

    func testDeleteEntry() {
        let store = makeStore()
        _ = store.addEntry(date: Date(), weather: .foggy, mood: 3, note: "", isPro: false)
        guard let id = store.entries.first?.id else { return XCTFail("no entry") }
        store.deleteEntry(id)
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testDeleteAllData() {
        let store = makeStore()
        _ = store.addEntry(date: Date(), weather: .snowy, mood: 2, note: "", isPro: false)
        _ = store.addEntry(date: Date(), weather: .sunny, mood: 5, note: "", isPro: false)
        store.deleteAllData()
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testCorrelationStatsComputesAverage() {
        let store = makeStore()
        _ = store.addEntry(date: Date(), weather: .rainy, mood: 2, note: "", isPro: false)
        _ = store.addEntry(date: Date(), weather: .rainy, mood: 4, note: "", isPro: false)
        _ = store.addEntry(date: Date(), weather: .sunny, mood: 5, note: "", isPro: false)
        let stats = store.correlationStats
        let rainyStat = stats.first { $0.weather == .rainy }
        XCTAssertNotNil(rainyStat)
        XCTAssertEqual(rainyStat?.averageMood ?? 0, 3.0, accuracy: 0.001)
        XCTAssertEqual(rainyStat?.entryCount, 2)
    }

    func testCorrelationStatsSortedDescending() {
        let store = makeStore()
        _ = store.addEntry(date: Date(), weather: .stormy, mood: 1, note: "", isPro: false)
        _ = store.addEntry(date: Date(), weather: .sunny, mood: 5, note: "", isPro: false)
        let stats = store.correlationStats
        XCTAssertEqual(stats.first?.weather, .sunny)
        XCTAssertEqual(stats.last?.weather, .stormy)
    }

    func testSortedEntriesNewestFirst() {
        let store = makeStore()
        let earlier = Date().addingTimeInterval(-86400)
        let later = Date()
        _ = store.addEntry(date: earlier, weather: .cloudy, mood: 3, note: "earlier", isPro: false)
        _ = store.addEntry(date: later, weather: .sunny, mood: 4, note: "later", isPro: false)
        XCTAssertEqual(store.sortedEntries.first?.note, "later")
    }

    func testPersistenceRoundTrip() {
        let fileName = "test_persist_\(UUID().uuidString).json"
        let store1 = OvercastStore(fileName: fileName)
        _ = store1.addEntry(date: Date(), weather: .sunny, mood: 5, note: "persisted", isPro: false)
        let store2 = OvercastStore(fileName: fileName)
        XCTAssertEqual(store2.entries.count, 1)
        XCTAssertEqual(store2.entries.first?.note, "persisted")
    }

    func testSkyColorInterpolatesFromSlateToSunbeam() {
        let low = OCTheme.skyColor(forMood: 1)
        let high = OCTheme.skyColor(forMood: 5)
        XCTAssertNotEqual(low, high)
    }
}
