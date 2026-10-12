import XCTest

final class FlowTests: XCTestCase {
    @MainActor
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Chorus idea"].waitForExistence(timeout: 30))
        return app
    }

    private func pause(_ seconds: Double) {
        Thread.sleep(forTimeInterval: seconds)
    }

    @MainActor
    func testRecordStopRecordAgain() {
        let app = launch()
        for round in 1...3 {
            app.buttons["Record"].tap()
            XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout: 2))
            pause(1.5)
            app.buttons["Stop"].tap()
            let title = round == 1 ? "New Recording" : "New Recording \(round)"
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 2))
            pause(1)
        }
    }

    @MainActor
    func testExpandSheetPauseResumeDone() {
        let app = launch()
        app.buttons["Record"].tap()
        let stop = app.buttons["Stop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 2))
        pause(1.5)
        let start = stop.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -2.5))
        start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)), withVelocity: .default, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
        pause(1)
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 2))
        pause(1)
        app.buttons["Resume"].tap()
        pause(1)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["New Recording"].waitForExistence(timeout: 2))
        pause(1)
    }

    @MainActor
    func testRowExpandCollapse() {
        let app = launch()
        pause(1)
        for (title, x) in [("Standup notes", 0.5), ("Call with Maya", 2.5), ("Call with Maya", 2.5), ("Standup notes", 0.5), ("Standup notes", 2.5)] {
            app.staticTexts[title].coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.5)).press(forDuration: 0.2)
            pause(1)
        }
        app.buttons["Select"].tap()
        app.staticTexts["Chorus idea"].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: -26, dy: 0)).tap()
        XCTAssertTrue(app.staticTexts["1 Selected"].waitForExistence(timeout: 2))
        app.buttons["Done"].tap()
        pause(1)
    }

    @MainActor
    func testRowToPlayerAndOptions() {
        let app = launch()
        app.staticTexts["Standup notes"].tap()
        pause(1)
        app.buttons["Edit Recording"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 2))
        pause(1)
        app.buttons["Playback Options"].tap()
        pause(1)
        app.buttons["Done"].firstMatch.tap()
        pause(1)
        app.buttons["Done"].firstMatch.tap()
        pause(1)
    }
}
