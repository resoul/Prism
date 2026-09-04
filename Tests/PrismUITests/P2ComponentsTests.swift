import XCTest
@testable import PrismUI

@MainActor
final class P2ComponentsTests: XCTestCase {
    // MARK: - 1. Kbd Tests

    func testKbdKeycapAndAccessibility() {
        let kbd = Kbd("⌘")
        let element = kbd.render()

        XCTAssertEqual(element.props.custom["role"], "keyboardKey")
        XCTAssertEqual(element.props.accessibilityLabel, "Command")

        let customKbd = Kbd("CustomKey", accessibleLabel: "Custom Key Description")
        let customElement = customKbd.render()
        XCTAssertEqual(customElement.props.accessibilityLabel, "Custom Key Description")
    }

    // MARK: - 2. CodeBlock Tests

    func testCodeBlockSafeRenderingAndCopy() {
        var copyInvoked = false
        let snippet = "let x = 42\nprint(x)"
        let block = CodeBlock(code: snippet, language: "swift", showLineNumbers: true) {
            copyInvoked = true
        }

        let element = block.render()
        XCTAssertEqual(element.props.custom["role"], "code")
        XCTAssertTrue(element.props.accessibilityLabel?.contains("swift") ?? false)

        block.onCopy?()
        XCTAssertTrue(copyInvoked)
    }

    // MARK: - 3. Skeleton Tests

    func testSkeletonShapesAndReduceMotion() {
        let circle = Skeleton(shape: .circle, width: 32, height: 32)
        let circleElement = circle.render()
        XCTAssertEqual(circleElement.props.accessibilityLabel, "Loading...")

        let rounded = Skeleton(shape: .rounded(radius: 8), width: 100, height: 20)
        let roundedElement = rounded.render()
        if case .sdfRoundedRect(let radius, let bw, _, _) = roundedElement.modifiers.first {
            XCTAssertEqual(radius, 8)
            XCTAssertEqual(bw, 0)
        } else {
            XCTFail("Expected sdfRoundedRect modifier on rounded skeleton")
        }
    }

    func testSkeletonReduceMotionSuppressesAnimation() {
        var contextNormal = ComponentContext.default
        contextNormal.environment.reduceMotion = false

        let skeletonNormal = Skeleton(width: 50, height: 20)
        let normalElement = skeletonNormal.body(context: contextNormal)
        XCTAssertTrue(normalElement.modifiers.contains(where: {
            if case .animation = $0 { return true }
            return false
        }))

        var contextReduce = ComponentContext.default
        contextReduce.environment.reduceMotion = true

        let skeletonReduce = Skeleton(width: 50, height: 20)
        let reduceElement = skeletonReduce.body(context: contextReduce)
        XCTAssertFalse(reduceElement.modifiers.contains(where: {
            if case .animation = $0 { return true }
            return false
        }))
    }

    // MARK: - 4. Empty State Tests

    func testEmptyStateComponent() {
        var actionClicked = false
        let empty = Empty(
            title: "No Records",
            description: "Try adjusting your search criteria.",
            iconName: "magnifyingglass",
            actionTitle: "Reset",
            onAction: { actionClicked = true }
        )

        let element = empty.render()
        XCTAssertEqual(element.props.custom["role"], "group")
        XCTAssertTrue(element.props.accessibilityLabel?.contains("No Records") ?? false)
        XCTAssertTrue(element.props.accessibilityLabel?.contains("Try adjusting") ?? false)

        empty.onAction?()
        XCTAssertTrue(actionClicked)
    }

    // MARK: - 5. Table Tests

    func testTableStructureAndStriping() {
        let cols = [
            TableColumn(title: "Name", width: 120),
            TableColumn(title: "Role", width: 100)
        ]
        let rows = [
            TableRow(cells: ["Alice", "Engineer"]),
            TableRow(cells: ["Bob", "Designer"])
        ]

        let table = Table(columns: cols, rows: rows, isStriped: true)
        let element = table.render()

        XCTAssertEqual(element.props.custom["role"], "table")
        XCTAssertTrue(element.props.accessibilityLabel?.contains("2 columns") ?? false)
        XCTAssertTrue(element.props.accessibilityLabel?.contains("2 rows") ?? false)
    }

    // MARK: - 6. Timeline Tests

    func testTimelineMilestones() {
        let items = [
            TimelineItem(title: "Kickoff", timestamp: "09:00", description: "Project start", status: .completed),
            TimelineItem(title: "Design", timestamp: "12:00", status: .active),
            TimelineItem(title: "Launch", timestamp: "18:00", status: .upcoming)
        ]

        let timeline = Timeline(items: items)
        let element = timeline.render()

        XCTAssertEqual(element.props.custom["role"], "list")
        XCTAssertTrue(element.props.accessibilityLabel?.contains("3 milestones") ?? false)
    }

    // MARK: - 7. HoverCard Tests

    func testHoverCardPortalInjectionWhenOpen() {
        let cardClosed = HoverCard(isOpen: false, anchor: {
            Text("Hover Me")
        }, card: {
            Text("Preview Card Content")
        })

        let closedElement = cardClosed.render()
        XCTAssertEqual(closedElement.children.count, 1) // Only anchor

        let cardOpen = HoverCard(isOpen: true, anchor: {
            Text("Hover Me")
        }, card: {
            Text("Preview Card Content")
        })

        let openElement = cardOpen.render()
        XCTAssertEqual(openElement.children.count, 2) // Anchor + Portal HoverCardBubble
        XCTAssertTrue(openElement.children.contains(where: {
            if case .portal(let target) = $0.kind, target == .floating { return true }
            return false
        }))
    }

    // MARK: - 8. AspectRatio Tests

    func testAspectRatioSizeResolution() {
        let ratio16_9 = AspectRatio(16.0 / 9.0) {
            Text("Content")
        }

        // 1. Constrained width, unconstrained height
        let (w1, h1) = ratio16_9.resolveSize(availableWidth: 160, availableHeight: nil)
        XCTAssertEqual(w1, 160)
        XCTAssertEqual(h1, 90)

        // 2. Unconstrained width, constrained height
        let (w2, h2) = ratio16_9.resolveSize(availableWidth: nil, availableHeight: 90)
        XCTAssertEqual(w2, 160)
        XCTAssertEqual(h2, 90)

        // 3. Both constrained (.fit mode)
        let (w3, h3) = ratio16_9.resolveSize(availableWidth: 160, availableHeight: 50)
        XCTAssertEqual(h3, 50)
        XCTAssertEqual(w3, 50 * (16.0 / 9.0), accuracy: 0.001)

        // 4. Both constrained (.fill mode)
        let ratioFill = AspectRatio(16.0 / 9.0, contentMode: .fill) {
            Text("Content")
        }
        let (w4, h4) = ratioFill.resolveSize(availableWidth: 160, availableHeight: 50)
        XCTAssertEqual(w4, 160)
        XCTAssertEqual(h4, 90)
    }

    // MARK: - 9. Accordion & Collapsible Tests

    func testCollapsibleToggle() {
        var expanded = false
        let collapsible = Collapsible(
            title: "FAQ Item",
            isExpanded: Binding(get: { expanded }, set: { expanded = $0 })
        ) {
            Text("Answer details")
        }

        let elementClosed = collapsible.render()
        XCTAssertEqual(elementClosed.children.count, 1) // Only header button

        expanded = true
        let elementOpen = collapsible.render()
        XCTAssertEqual(elementOpen.children.count, 2) // Header + disclosed content
    }

    func testAccordionSingleModeMutualExclusion() {
        var expandedSet: Set<String> = ["item-1"]
        let accordion = Accordion(
            items: [
                AccordionItem(id: "item-1", title: "Section 1") { Text("Content 1") },
                AccordionItem(id: "item-2", title: "Section 2") { Text("Content 2") }
            ],
            mode: .single,
            expandedIDs: Binding(get: { expandedSet }, set: { expandedSet = $0 })
        )

        let element = accordion.render()
        XCTAssertEqual(element.children.count, 2)
        XCTAssertEqual(expandedSet, ["item-1"])
    }

    // MARK: - 10. Demo Screen Integration Test

    func testP2DemoScreenBuildsCohesively() {
        let demo = P2DemoScreen(isHoverCardOpen: true, expandedAccordionSections: ["faq-1"])
        let element = demo.render()

        XCTAssertFalse(element.children.isEmpty)
        XCTAssertTrue(element.children.count >= 8) // All 8 sections present
    }
}
