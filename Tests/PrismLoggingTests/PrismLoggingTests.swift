import XCTest
@testable import PrismLogging

final class PrismLoggingTests: XCTestCase {
    func testLoggingSubsystem() {
        XCTAssertEqual(PrismLogging.subsystem, "dev.prism.ui")
    }

    struct TestEvent: PrismLogEvent {
        let category: String = "test"
        let message: String = "hello log"
    }

    func testLogEvent() {
        let event = TestEvent()
        XCTAssertEqual(event.category, "test")
        XCTAssertEqual(event.message, "hello log")
    }
}
