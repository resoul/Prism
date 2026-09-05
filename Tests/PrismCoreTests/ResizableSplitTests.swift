import XCTest
@testable import PrismCore

final class ResizableSplitTests: XCTestCase {
    func testConstraintsKeyboardRTLAndCaptureCancel() {
        var split = ResizableSplit(ratio: 0.5, minimumRatio: 0.2, maximumRatio: 0.8)
        split.setRatio(2); XCTAssertEqual(split.ratio, 0.8)
        split.keyboardResize(steps: 1, rtl: true); XCTAssertEqual(split.ratio, 0.78, accuracy: 0.0001)
        split.beginCapture(); split.updateCapture(delta: 100, availableExtent: 1_000); XCTAssertEqual(split.ratio, 0.8)
        split.cancelCapture(); XCTAssertEqual(split.ratio, 0.78); XCTAssertFalse(split.isCapturing)
    }
    func testNestedPanelsRemainBoundedAndCommitCapture() {
        var outer = ResizableSplit(ratio: 0.4); var inner = ResizableSplit(ratio: 0.6, minimumRatio: 0.3, maximumRatio: 0.7)
        outer.beginCapture(); outer.updateCapture(delta: -80, availableExtent: 800); outer.endCapture()
        inner.beginCapture(); inner.updateCapture(delta: 200, availableExtent: 400); inner.endCapture()
        XCTAssertTrue((0.1...0.9).contains(outer.ratio)); XCTAssertEqual(inner.ratio, 0.7)
    }
}
