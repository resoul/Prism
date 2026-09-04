import XCTest
@testable import PrismCore

final class FlexLayoutTests: XCTestCase {
    // MARK: - 1. Golden Frame: Row Layout with Gaps & Padding

    func testRowLayoutGoldenFrames() {
        let child1 = LayoutNode(id: ElementID(typeName: "Box1"), style: LayoutStyle(width: .fixed(60), height: .fixed(40)))
        let child2 = LayoutNode(id: ElementID(typeName: "Box2"), style: LayoutStyle(width: .fixed(80), height: .fixed(50)))
        let child3 = LayoutNode(id: ElementID(typeName: "Box3"), style: LayoutStyle(width: .fixed(100), height: .fixed(30)))

        let row = LayoutNode(
            id: ElementID(typeName: "Row"),
            style: LayoutStyle(
                padding: DirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15),
                direction: .row,
                alignItems: .center,
                gap: 10
            ),
            children: [child1, child2, child3]
        )

        // Measure pass
        let measured = row.measure(constraint: .unconstrained)
        // Width: 15 (lead) + 60 + 10 (gap) + 80 + 10 (gap) + 100 + 15 (trail) = 290
        // Height: 10 (top) + 50 (max child) + 10 (bottom) = 70
        XCTAssertEqual(measured.width, 290)
        XCTAssertEqual(measured.height, 70)

        // Layout pass
        row.layout(frame: LayoutFrame(x: 0, y: 0, width: 290, height: 70))

        // Check child1 (centered vertically in 50pt content height -> y: 10 + (50 - 40)/2 = 15)
        XCTAssertEqual(child1.layoutFrame?.origin.x, 15)
        XCTAssertEqual(child1.layoutFrame?.origin.y, 15)
        XCTAssertEqual(child1.layoutFrame?.width, 60)
        XCTAssertEqual(child1.layoutFrame?.height, 40)

        // Check child2 (x: 15 + 60 + 10 = 85, y: 10 + (50 - 50)/2 = 10)
        XCTAssertEqual(child2.layoutFrame?.origin.x, 85)
        XCTAssertEqual(child2.layoutFrame?.origin.y, 10)
        XCTAssertEqual(child2.layoutFrame?.width, 80)
        XCTAssertEqual(child2.layoutFrame?.height, 50)

        // Check child3 (x: 85 + 80 + 10 = 175, y: 10 + (50 - 30)/2 = 20)
        XCTAssertEqual(child3.layoutFrame?.origin.x, 175)
        XCTAssertEqual(child3.layoutFrame?.origin.y, 20)
        XCTAssertEqual(child3.layoutFrame?.width, 100)
        XCTAssertEqual(child3.layoutFrame?.height, 30)
    }

    // MARK: - 2. Golden Frame: Column Layout with Alignment

    func testColumnLayoutGoldenFrames() {
        let child1 = LayoutNode(id: ElementID(typeName: "Item1"), style: LayoutStyle(width: .fixed(50), height: .fixed(30)))
        let child2 = LayoutNode(id: ElementID(typeName: "Item2"), style: LayoutStyle(width: .fixed(100), height: .fixed(40)))

        let column = LayoutNode(
            id: ElementID(typeName: "Col"),
            style: LayoutStyle(
                direction: .column,
                justifyContent: .start,
                alignItems: .end,
                gap: 8
            ),
            children: [child1, child2]
        )

        column.measure(constraint: .unconstrained)
        column.layout(frame: LayoutFrame(x: 0, y: 0, width: 120, height: 100))

        // child1: end alignment in 120 width -> x: 120 - 50 = 70, y: 0
        XCTAssertEqual(child1.layoutFrame?.origin.x, 70)
        XCTAssertEqual(child1.layoutFrame?.origin.y, 0)
        XCTAssertEqual(child1.layoutFrame?.width, 50)
        XCTAssertEqual(child1.layoutFrame?.height, 30)

        // child2: end alignment in 120 width -> x: 120 - 100 = 20, y: 30 + 8 = 38
        XCTAssertEqual(child2.layoutFrame?.origin.x, 20)
        XCTAssertEqual(child2.layoutFrame?.origin.y, 38)
        XCTAssertEqual(child2.layoutFrame?.width, 100)
        XCTAssertEqual(child2.layoutFrame?.height, 40)
    }

    // MARK: - 3. Flex Grow & Shrink Distribution

    func testFlexGrowDistribution() {
        let item1 = LayoutNode(id: ElementID(typeName: "A"), style: LayoutStyle(width: .fixed(100), flexGrow: 1.0))
        let item2 = LayoutNode(id: ElementID(typeName: "B"), style: LayoutStyle(width: .fixed(100), flexGrow: 2.0))

        let container = LayoutNode(
            id: ElementID(typeName: "Row"),
            style: LayoutStyle(direction: .row),
            children: [item1, item2]
        )

        container.measure(constraint: .atMost(width: 500, height: 100))
        // Frame width is 500. Base items are 100 + 100 = 200. Free space = 300.
        // item1 gets 300 * (1/3) = 100 -> final width: 200
        // item2 gets 300 * (2/3) = 200 -> final width: 300
        container.layout(frame: LayoutFrame(x: 0, y: 0, width: 500, height: 100))

        XCTAssertEqual(item1.layoutFrame?.origin.x, 0)
        XCTAssertEqual(item1.layoutFrame?.width, 200)

        XCTAssertEqual(item2.layoutFrame?.origin.x, 200)
        XCTAssertEqual(item2.layoutFrame?.width, 300)
    }

    func testFlexShrinkDistribution() {
        let item1 = LayoutNode(id: ElementID(typeName: "A"), style: LayoutStyle(width: .fixed(200), flexShrink: 1.0))
        let item2 = LayoutNode(id: ElementID(typeName: "B"), style: LayoutStyle(width: .fixed(200), flexShrink: 1.0))

        let container = LayoutNode(
            id: ElementID(typeName: "Row"),
            style: LayoutStyle(direction: .row),
            children: [item1, item2]
        )

        container.measure(constraint: .atMost(width: 300, height: 100))
        // Frame width is 300. Total base = 400. Overflow = 100.
        // Equal shrink -> each shrinks by 50 -> final width: 150 each
        container.layout(frame: LayoutFrame(x: 0, y: 0, width: 300, height: 100))

        XCTAssertEqual(item1.layoutFrame?.width, 150)
        XCTAssertEqual(item2.layoutFrame?.width, 150)
    }

    // MARK: - 4. JustifyContent Tests

    func testJustifyContentSpaceBetween() {
        let item1 = LayoutNode(id: ElementID(typeName: "1"), style: LayoutStyle(width: .fixed(50)))
        let item2 = LayoutNode(id: ElementID(typeName: "2"), style: LayoutStyle(width: .fixed(50)))

        let row = LayoutNode(
            id: ElementID(typeName: "Row"),
            style: LayoutStyle(direction: .row, justifyContent: .spaceBetween),
            children: [item1, item2]
        )

        row.measure(constraint: .unconstrained)
        // 200 width. Total items = 100. Remaining = 100. Space between 2 items = 100.
        row.layout(frame: LayoutFrame(x: 0, y: 0, width: 200, height: 50))

        XCTAssertEqual(item1.layoutFrame?.origin.x, 0)
        XCTAssertEqual(item2.layoutFrame?.origin.x, 150)
    }

    func testJustifyContentCenter() {
        let item = LayoutNode(id: ElementID(typeName: "1"), style: LayoutStyle(width: .fixed(80)))

        let row = LayoutNode(
            id: ElementID(typeName: "Row"),
            style: LayoutStyle(direction: .row, justifyContent: .center),
            children: [item]
        )

        row.measure(constraint: .unconstrained)
        // 200 width. 80 item. Remaining = 120. Centered at 60.
        row.layout(frame: LayoutFrame(x: 0, y: 0, width: 200, height: 50))

        XCTAssertEqual(item.layoutFrame?.origin.x, 60)
        XCTAssertEqual(item.layoutFrame?.width, 80)
    }

    // MARK: - 5. Flex Wrap

    func testFlexWrapMultiLine() {
        let item1 = LayoutNode(id: ElementID(typeName: "1"), style: LayoutStyle(width: .fixed(100), height: .fixed(40)))
        let item2 = LayoutNode(id: ElementID(typeName: "2"), style: LayoutStyle(width: .fixed(100), height: .fixed(40)))
        let item3 = LayoutNode(id: ElementID(typeName: "3"), style: LayoutStyle(width: .fixed(100), height: .fixed(40)))

        let wrapRow = LayoutNode(
            id: ElementID(typeName: "WrapRow"),
            style: LayoutStyle(
                direction: .row,
                flexWrap: .wrap,
                gap: 10,
                crossGap: 12
            ),
            children: [item1, item2, item3]
        )

        // In 250 pt container: item1 (100) + gap (10) + item2 (100) = 210 <= 250 (Line 1).
        // item3 (100) exceeds 250, wraps to Line 2.
        wrapRow.measure(constraint: .atMost(width: 250, height: 300))
        wrapRow.layout(frame: LayoutFrame(x: 0, y: 0, width: 250, height: 100))

        // Line 1 items: y = 0
        XCTAssertEqual(item1.layoutFrame?.origin.x, 0)
        XCTAssertEqual(item1.layoutFrame?.origin.y, 0)

        XCTAssertEqual(item2.layoutFrame?.origin.x, 110)
        XCTAssertEqual(item2.layoutFrame?.origin.y, 0)

        // Line 2 item: y = 40 (line 1 height) + 12 (crossGap) = 52
        XCTAssertEqual(item3.layoutFrame?.origin.x, 0)
        XCTAssertEqual(item3.layoutFrame?.origin.y, 52)
    }

    // MARK: - 6. Absolute Positioning & Containing Block

    func testAbsolutePositioningDoesNotAffectFlowMeasurement() {
        let flowChild = LayoutNode(id: ElementID(typeName: "Flow"), style: LayoutStyle(width: .fixed(100), height: .fixed(50)))
        let absoluteChild = LayoutNode(
            id: ElementID(typeName: "Overlay"),
            style: LayoutStyle(
                width: .fixed(80),
                height: .fixed(30),
                positionType: .absolute,
                offsets: EdgeOffsets(top: 10, trailing: 15),
                zIndex: 10
            )
        )

        let container = LayoutNode(
            id: ElementID(typeName: "Card"),
            style: LayoutStyle(direction: .column),
            children: [flowChild, absoluteChild]
        )

        // Measured size must only reflect flow child (100x50), completely ignoring absoluteChild!
        let measured = container.measure(constraint: .unconstrained)
        XCTAssertEqual(measured.width, 100)
        XCTAssertEqual(measured.height, 50)

        // Layout container at 200x100
        container.layout(frame: LayoutFrame(x: 0, y: 0, width: 200, height: 100))

        // Flow child at origin
        XCTAssertEqual(flowChild.layoutFrame?.origin.x, 0)
        XCTAssertEqual(flowChild.layoutFrame?.origin.y, 0)

        // Absolute child positioned with top: 10, trailing: 15
        // x: 200 - 15 - 80 = 105, y: 10
        XCTAssertEqual(absoluteChild.layoutFrame?.origin.x, 105)
        XCTAssertEqual(absoluteChild.layoutFrame?.origin.y, 10)
        XCTAssertEqual(absoluteChild.layoutFrame?.width, 80)
        XCTAssertEqual(absoluteChild.layoutFrame?.height, 30)
    }

    // MARK: - 7. Corner Cases & Layout Trace

    func testEmptyContainerMeasuresToPadding() {
        let empty = LayoutNode(
            id: ElementID(typeName: "EmptyCard"),
            style: LayoutStyle(padding: DirectionalEdgeInsets(all: 16))
        )
        let measured = empty.measure(constraint: .unconstrained)
        XCTAssertEqual(measured.width, 32)
        XCTAssertEqual(measured.height, 32)
    }

    func testLayoutTraceFormatting() {
        let child = LayoutNode(
            id: ElementID(typeName: "Title"),
            style: LayoutStyle(width: .fixed(120), height: .fixed(24))
        )
        let root = LayoutNode(
            id: ElementID(typeName: "RootStack"),
            style: LayoutStyle(direction: .column, gap: 8),
            children: [child]
        )

        root.measure(constraint: .atMost(width: 320, height: 480))
        root.layout(frame: LayoutFrame(x: 0, y: 0, width: 320, height: 100))

        let trace = root.dumpTrace()
        XCTAssertTrue(trace.contains("Node(RootStack@0)"))
        XCTAssertTrue(trace.contains("frame: (0.0, 0.0, 320.0, 100.0)"))
        XCTAssertTrue(trace.contains("dir: column"))
        XCTAssertTrue(trace.contains("gap: 8.0"))
        XCTAssertTrue(trace.contains("Node(Title@0)"))
        XCTAssertTrue(trace.contains("frame: (0.0, 0.0, 120.0, 24.0)"))
    }
}
