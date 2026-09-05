import XCTest

final class ShowcaseLaunchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesWithDeterministicResetArgument() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testNativeIncrementAndResetInteraction() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let counter = app.staticTexts["showcase.counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 3))
        XCTAssertEqual(counter.label, "Counter: 0")

        let incrementBtn = app.buttons["showcase.increment"]
        XCTAssertTrue(incrementBtn.waitForExistence(timeout: 3))
        incrementBtn.tap()

        // Verify count updated through native event -> Flux state -> host re-render
        let counterUpdated = app.staticTexts["showcase.counter"]
        XCTAssertTrue(counterUpdated.waitForExistence(timeout: 3))
        XCTAssertEqual(counterUpdated.label, "Counter: 1")

        // Increment again
        incrementBtn.tap()
        XCTAssertEqual(counter.label, "Counter: 2")

        // Reset
        let resetBtn = app.buttons["showcase.reset"]
        XCTAssertTrue(resetBtn.waitForExistence(timeout: 3))
        resetBtn.tap()

        XCTAssertEqual(counter.label, "Counter: 0")
    }

    func testNativeInputAndScrollControls() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let title = app.staticTexts["showcase.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))

        let scrollStatus = app.staticTexts["showcase.scroll_status"]
        XCTAssertTrue(scrollStatus.waitForExistence(timeout: 3))
        XCTAssertEqual(scrollStatus.label, "Scroll offset: 0")

        let scrollDownBtn = app.buttons["showcase.scroll_down"]
        XCTAssertTrue(scrollDownBtn.waitForExistence(timeout: 3))
        scrollDownBtn.tap()

        XCTAssertEqual(scrollStatus.label, "Scroll offset: 20")
    }
}
