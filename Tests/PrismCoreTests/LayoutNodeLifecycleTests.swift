import XCTest
@testable import PrismCore

final class LayoutNodeLifecycleTests: XCTestCase {
    // MARK: - 1. Two-pass Lifecycle & Invalidation State

    func testTwoPassLifecycleAndInvalidationTransitions() {
        let node = LayoutNode(
            id: ElementID(typeName: "Box"),
            style: LayoutStyle(width: .fixed(100), height: .fixed(50))
        )

        // Initial state
        XCTAssertEqual(node.invalidationState, .measureInvalidated)
        XCTAssertNil(node.measuredSize)
        XCTAssertNil(node.layoutFrame)

        // Pass 1: Measure
        let measured = node.measure(constraint: .unconstrained)
        XCTAssertEqual(measured.width, 100)
        XCTAssertEqual(measured.height, 50)
        XCTAssertEqual(node.measuredSize, measured)
        XCTAssertEqual(node.invalidationState, .layoutInvalidated)
        XCTAssertEqual(node.debugData.desiredSize, measured)

        // Pass 2: Layout
        let frame = LayoutFrame(x: 10, y: 20, width: 100, height: 50)
        node.layout(frame: frame)
        XCTAssertEqual(node.layoutFrame, frame)
        XCTAssertEqual(node.invalidationState, .clean)
        XCTAssertEqual(node.debugData.assignedFrame, frame)

        // Frame-only invalidation
        node.invalidateLayout()
        XCTAssertEqual(node.invalidationState, .layoutInvalidated)
        XCTAssertEqual(node.measuredSize, measured) // Measure cache preserved
        XCTAssertNil(node.layoutFrame)

        // Style change -> full measure invalidation
        node.style.width = .fixed(150)
        XCTAssertEqual(node.invalidationState, .measureInvalidated)
        XCTAssertNil(node.measuredSize) // Measure cache cleared
    }

    // MARK: - 2. Shape Measure Policy

    func testShapeMeasurement() {
        let rectPolicy = ShapeMeasurePolicy(shapeType: .rectangle, defaultDiameter: 60)
        let rectSize = rectPolicy.measure(
            style: LayoutStyle(width: .fixed(80), height: .fixed(40)),
            constraint: .unconstrained
        )
        XCTAssertEqual(rectSize.width, 80)
        XCTAssertEqual(rectSize.height, 40)

        let circlePolicy = ShapeMeasurePolicy(shapeType: .circle, defaultDiameter: 50)
        let circleSize = circlePolicy.measure(
            style: .default,
            constraint: .unconstrained
        )
        XCTAssertEqual(circleSize.width, 50)
        XCTAssertEqual(circleSize.height, 50)
    }

    // MARK: - 3. Spacer Measure Policy

    func testSpacerMeasurement() {
        let spacerPolicy = SpacerMeasurePolicy(minLength: 16, axis: .vertical)

        // In unbounded space: collapses to minLength
        let unconstrained = spacerPolicy.measure(style: .default, constraint: .unconstrained)
        XCTAssertEqual(unconstrained.height, 16)

        // In bounded space: expands to fill available
        let bounded = spacerPolicy.measure(style: .default, constraint: .atMost(height: 120))
        XCTAssertEqual(bounded.height, 120)
    }

    // MARK: - 4. Debug Data Inspection

    func testDebugDataInspection() {
        let node = LayoutNode(
            id: ElementID(typeName: "Item"),
            style: LayoutStyle(width: .fixed(200), height: .fixed(80))
        )

        let constraint = SizeConstraint.atMost(width: 400, height: 300)
        node.measure(constraint: constraint)
        node.layout(frame: LayoutFrame(x: 0, y: 0, width: 200, height: 80))

        let debug = node.debugData
        XCTAssertEqual(debug.measureConstraint, constraint)
        XCTAssertEqual(debug.desiredSize, MeasuredSize(width: 200, height: 80))
        XCTAssertEqual(debug.assignedFrame, LayoutFrame(x: 0, y: 0, width: 200, height: 80))

        let desc = debug.description
        XCTAssertTrue(desc.contains("desired: MeasuredSize(w: 200.0, h: 80.0)"))
        XCTAssertTrue(desc.contains("frame: LayoutFrame(x: 0.0, y: 0.0, w: 200.0, h: 80.0)"))
    }
}
