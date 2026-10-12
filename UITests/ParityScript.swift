import XCTest

/// The fixed script recorded on device in both Voice Memos and retake (parity/README.md).
/// Every move is followed by a one-second rest so the scorer can split the recording into moves.
final class ParityScript: XCTestCase {
    @MainActor
    func testParityScript() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Chorus idea"].waitForExistence(timeout: 30))
        rest(2)

        app.staticTexts["Chorus idea"].tap()
        rest()
        app.staticTexts["Standup notes"].tap()
        rest()
        app.staticTexts["Standup notes"].tap()
        rest()

        app.staticTexts["Chorus idea"].tap()
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
        XCTAssertTrue(app.staticTexts["New Recording"].waitForExistence(timeout: 2))
        rest()

        app.buttons["Select"].tap()
        rest()
        app.staticTexts["New Recording"].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: -26, dy: 0)).tap()
        XCTAssertTrue(app.staticTexts["1 Selected"].waitForExistence(timeout: 2))
        rest()
        app.buttons["Done"].firstMatch.tap()
        rest()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        rest()
        app.staticTexts["All Recordings"].tap()
        rest(1.5)
    }

    private func rest(_ seconds: Double = 1) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
