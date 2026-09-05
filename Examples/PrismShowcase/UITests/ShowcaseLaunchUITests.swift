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

        let title = app.staticTexts["showcase.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))

        let browseBtn = app.buttons["showcase.welcome.browse"]
        XCTAssertTrue(browseBtn.waitForExistence(timeout: 3))
    }

    func testNavigationFromWelcomeToCategoriesAndDetail() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let browseBtn = app.buttons["showcase.welcome.browse"]
        XCTAssertTrue(browseBtn.waitForExistence(timeout: 3))
        browseBtn.tap()

        let categoriesTitle = app.staticTexts["showcase.categories.title"]
        XCTAssertTrue(categoriesTitle.waitForExistence(timeout: 3))

        let formsCategory = app.buttons["showcase.category.forms"]
        XCTAssertTrue(formsCategory.waitForExistence(timeout: 3))
        formsCategory.tap()

        let categoryTitle = app.staticTexts["showcase.category.title"]
        XCTAssertTrue(categoryTitle.waitForExistence(timeout: 3))

        let counterComp = app.buttons["showcase.component.counter"]
        XCTAssertTrue(counterComp.waitForExistence(timeout: 3))
        counterComp.tap()

        let counter = app.staticTexts["showcase.counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 3))

        let backBtn = app.buttons["showcase.navigation.back"]
        XCTAssertTrue(backBtn.waitForExistence(timeout: 3))
        backBtn.tap()

        // Returned to category list
        XCTAssertTrue(categoryTitle.waitForExistence(timeout: 3))
    }

    func testNativeIncrementAndResetInteraction() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset", "-showcaseRoute", "counter"]
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
        app.launchArguments = ["-showcaseReset", "-showcaseRoute", "counter"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let scrollStatus = app.staticTexts["showcase.scroll_status"]
        XCTAssertTrue(scrollStatus.waitForExistence(timeout: 3))
        XCTAssertEqual(scrollStatus.label, "Scroll offset: 0")

        let scrollDownBtn = app.buttons["showcase.scroll_down"]
        XCTAssertTrue(scrollDownBtn.waitForExistence(timeout: 3))
        scrollDownBtn.tap()

        XCTAssertEqual(scrollStatus.label, "Scroll offset: 20")
    }

    func testNotFoundRouteShowsRecoverableScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset", "-showcaseRoute", "component/nonexistent_xyz"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let notFoundTitle = app.staticTexts["showcase.not_found.title"]
        XCTAssertTrue(notFoundTitle.waitForExistence(timeout: 3))

        let returnBtn = app.buttons["showcase.not_found.return_button"]
        XCTAssertTrue(returnBtn.waitForExistence(timeout: 3))
        returnBtn.tap()

        let categoriesTitle = app.staticTexts["showcase.categories.title"]
        XCTAssertTrue(categoriesTitle.waitForExistence(timeout: 3))
    }
}
