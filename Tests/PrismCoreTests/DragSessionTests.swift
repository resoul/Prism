import XCTest
@testable import PrismCore

final class DragSessionTests: XCTestCase {
    func testDropAndScrollArbitration() {
        var session = DragSession()
        let item = ElementID(typeName: "Card", key: "one")
        let target = DragTarget(id: ElementID(typeName: "DropZone"), frame: CGRect(x: 10, y: 10, width: 80, height: 80))
        XCTAssertTrue(session.begin(itemID: item, at: CGPoint(x: 20, y: 20)))
        session.update(location: CGPoint(x: 20, y: 20), targets: [target], viewport: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(session.drop(), target.id)
        XCTAssertEqual(session.phase, .dropped)
        XCTAssertNil(session.pointerCaptureID)
    }

    func testUnmountAndInvalidDropCancelWithoutOrphanCapture() {
        var session = DragSession()
        let item = ElementID(typeName: "Row", key: "one")
        XCTAssertTrue(session.begin(itemID: item, at: .zero))
        session.unmount(itemID: item)
        XCTAssertEqual(session.phase, .cancelled)
        XCTAssertNil(session.pointerCaptureID)
        XCTAssertNil(session.drop())
    }
}
