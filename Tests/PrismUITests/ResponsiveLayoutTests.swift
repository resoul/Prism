import XCTest
import CoreGraphics
@testable import PrismUI
@testable import PrismCore

final class ResponsiveLayoutTests: XCTestCase {

    func testBreakpointThresholds() {
        // Compact: < 600
        XCTAssertEqual(Breakpoint.from(width: 320), .compact)
        XCTAssertEqual(Breakpoint.from(width: 375), .compact)
        XCTAssertEqual(Breakpoint.from(width: 599.9), .compact)
        XCTAssertTrue(Breakpoint.from(width: 400).isCompact)

        // Medium: 600..<900
        XCTAssertEqual(Breakpoint.from(width: 600), .medium)
        XCTAssertEqual(Breakpoint.from(width: 768), .medium)
        XCTAssertEqual(Breakpoint.from(width: 899.9), .medium)
        XCTAssertTrue(Breakpoint.from(width: 700).isMedium)

        // Expanded: 900...1200
        XCTAssertEqual(Breakpoint.from(width: 900), .expanded)
        XCTAssertEqual(Breakpoint.from(width: 1024), .expanded)
        XCTAssertEqual(Breakpoint.from(width: 1200), .expanded)
        XCTAssertTrue(Breakpoint.from(width: 1100).isExpanded)

        // Wide: > 1200
        XCTAssertEqual(Breakpoint.from(width: 1200.1), .wide)
        XCTAssertEqual(Breakpoint.from(width: 1440), .wide)
        XCTAssertEqual(Breakpoint.from(width: 2560), .wide)
        XCTAssertTrue(Breakpoint.from(width: 1600).isWide)
    }

    func testBreakpointComparableOrdering() {
        XCTAssertTrue(Breakpoint.compact < Breakpoint.medium)
        XCTAssertTrue(Breakpoint.medium < Breakpoint.expanded)
        XCTAssertTrue(Breakpoint.expanded < Breakpoint.wide)
    }

    func testResponsiveValueFallbackResolution() {
        // 1. All specified
        let full = ResponsiveValue<Int>(compact: 1, medium: 2, expanded: 3, wide: 4)
        XCTAssertEqual(full.resolve(for: .compact), 1)
        XCTAssertEqual(full.resolve(for: .medium), 2)
        XCTAssertEqual(full.resolve(for: .expanded), 3)
        XCTAssertEqual(full.resolve(for: .wide), 4)

        // 2. Only compact specified -> all inherit compact
        let minimal = ResponsiveValue<String>(compact: "base")
        XCTAssertEqual(minimal.resolve(for: .compact), "base")
        XCTAssertEqual(minimal.resolve(for: .medium), "base")
        XCTAssertEqual(minimal.resolve(for: .expanded), "base")
        XCTAssertEqual(minimal.resolve(for: .wide), "base")

        // 3. Compact and expanded specified
        let stepped = ResponsiveValue<Double>(compact: 16.0, expanded: 32.0)
        XCTAssertEqual(stepped.resolve(for: .compact), 16.0)
        XCTAssertEqual(stepped.resolve(for: .medium), 16.0) // Falls back to compact
        XCTAssertEqual(stepped.resolve(for: .expanded), 32.0)
        XCTAssertEqual(stepped.resolve(for: .wide), 32.0)   // Falls back to expanded
    }

    func testVisibilityModifiers() {
        let component = Text("Hello")
        let context = ComponentContext()

        // Visible only on compact
        let visibleOnCompact = component.visible(on: [.compact], current: .compact)
        let elVisible = visibleOnCompact.asRenderElements(in: context)
        XCTAssertEqual(elVisible.count, 1)
        XCTAssertNotEqual(elVisible[0].kind, .empty)

        // Hidden when on expanded
        let hiddenOnExpanded = component.visible(on: [.compact], current: .expanded)
        let elHidden = hiddenOnExpanded.asRenderElements(in: context)
        XCTAssertEqual(elHidden[0].kind, .empty)

        // Hidden modifier
        let explicitlyHidden = component.hidden(on: [.compact], current: .compact)
        XCTAssertEqual(explicitlyHidden.asRenderElements(in: context)[0].kind, .empty)

        let explicitlyShown = component.hidden(on: [.compact], current: .expanded)
        XCTAssertNotEqual(explicitlyShown.asRenderElements(in: context)[0].kind, .empty)
    }

    func testResizeOscillationStability() {
        // Oscillating around the 750 width threshold does not trigger breakpoint transitions
        let widths: [CGFloat] = [700, 750, 720, 850, 620, 890]
        for w in widths {
            XCTAssertEqual(Breakpoint.from(width: w), .medium)
        }
    }
}
