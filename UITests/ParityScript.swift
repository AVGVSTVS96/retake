import XCTest

/// The fixed script recorded on device in both Voice Memos and retake (parity/README.md).
/// Every move is followed by a one-second rest so the scorer can split the recording into moves.
/// Rows are found by position, so the script runs on the demo library or on a fixture of the reference's.
final class ParityScript: XCTestCase {
    @MainActor
    func testParityScript() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launchEnvironment["DEMO_FIXTURE"] = ProcessInfo.processInfo.environment["DEMO_FIXTURE"]
        app.launch()
        let rows = app.collectionViews.firstMatch.cells
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 30))
        rest(2)

        title(rows.element(boundBy: 0)).tap()
        rest()
        title(rows.element(boundBy: 1)).tap()
        rest()
        rows.element(boundBy: 1).textFields.firstMatch.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        rest()
        app.typeText("\n")
        rest()
        besideDate(rows.element(boundBy: 1)).tap()
        rest()

        title(rows.element(boundBy: 0)).tap()
        rest()
        app.buttons["More"].firstMatch.tap()
        rest()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        rest()

        app.buttons["Record"].tap()
        let stop = app.buttons["Stop"]
        XCTAssertTrue(stop.waitForExistence(timeout: 2))
        rest(3)
        stop.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -2.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)), withVelocity: .default, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
        rest()
        app.buttons["Pause"].tap()
        rest()
        app.buttons["Resume"].tap()
        rest()
        app.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForNonExistence(timeout: 2))
        rest()

        app.buttons["Record"].tap()
        XCTAssertTrue(stop.waitForExistence(timeout: 2))
        rest(3)
        stop.tap()
        XCTAssertTrue(stop.waitForNonExistence(timeout: 2))
        rest()

        app.buttons["Select"].tap()
        rest()
        title(rows.element(boundBy: 0)).coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: -26, dy: 0)).tap()
        XCTAssertTrue(app.staticTexts["1 Selected"].waitForExistence(timeout: 2))
        rest()
        app.buttons["Done"].firstMatch.tap()
        rest()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        rest()
        app.staticTexts["All Recordings"].tap()
        rest(1.5)
    }

    private func title(_ row: XCUIElement) -> XCUIElement {
        row.staticTexts.firstMatch
    }

    /// A spot on the row's date line, clear of the title, which renames an open row instead of closing it.
    private func besideDate(_ row: XCUIElement) -> XCUICoordinate {
        row.textFields.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
    }

    private func rest(_ seconds: Double = 1) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
