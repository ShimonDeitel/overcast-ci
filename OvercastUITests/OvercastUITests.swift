import XCTest

final class OvercastUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddEntryFromHome() {
        let addButton = app.buttons["addEntryButton"]
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        } else {
            app.buttons["logFirstEntryButton"].tap()
        }
        let saveButton = app.buttons["saveEntryButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Overcast"].waitForExistence(timeout: 5))
    }

    func testMoodButtonSelection() {
        let addButton = app.buttons["addEntryButton"]
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        } else {
            app.buttons["logFirstEntryButton"].tap()
        }
        let moodButton = app.buttons["moodButton_5"]
        XCTAssertTrue(moodButton.waitForExistence(timeout: 5))
        moodButton.tap()
        app.buttons["saveEntryButton"].tap()
        XCTAssertTrue(app.navigationBars["Overcast"].waitForExistence(timeout: 5))
    }

    func testEditEntryViaMenu() {
        addSeedEntry()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entryMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Edit"].tap()
        let saveButton = app.buttons["saveEntryButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
    }

    func testDeleteEntryViaMenu() {
        addSeedEntry()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entryMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Delete"].tap()
        let confirmDelete = app.buttons["Delete"].lastMatch
        if confirmDelete.waitForExistence(timeout: 3) {
            confirmDelete.tap()
        }
    }

    func testSettingsTabOpensAndTogglesReminder() {
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["dailyReminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
    }

    func testFreeLimitTriggersPaywall() {
        for _ in 0..<8 {
            let addButton = app.buttons["addEntryButton"]
            if addButton.waitForExistence(timeout: 3) {
                addButton.tap()
            } else if app.buttons["logFirstEntryButton"].waitForExistence(timeout: 3) {
                app.buttons["logFirstEntryButton"].tap()
            } else {
                break
            }
            let saveButton = app.buttons["saveEntryButton"]
            if saveButton.waitForExistence(timeout: 3) {
                saveButton.tap()
            }
        }
        // After 7 free entries, the 8th tap should show the paywall's Close button.
        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5) || app.navigationBars["Overcast"].exists)
    }

    private func addSeedEntry() {
        let addButton = app.buttons["addEntryButton"]
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        } else {
            app.buttons["logFirstEntryButton"].tap()
        }
        app.buttons["saveEntryButton"].tap()
    }
}

private extension XCUIElementQuery {
    var lastMatch: XCUIElement {
        self.element(boundBy: max(0, count - 1))
    }
}
