import XCTest

final class ShowcaseLaunchUITests: XCTestCase {
    func testLaunchesWithDeterministicResetArgument() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcaseReset"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
