import XCTest
@testable import PrismCore

final class HeaderCollapseCoordinatorTests: XCTestCase {

    func testInitialState() {
        let coordinator = HeaderCollapseCoordinator(expandedHeight: 188.0, collapsedHeight: 0.0, initialPage: 0)

        XCTAssertEqual(coordinator.expandedHeight, 188.0)
        XCTAssertEqual(coordinator.collapsedHeight, 0.0)
        XCTAssertEqual(coordinator.collapseRange, 188.0)
        XCTAssertEqual(coordinator.collapseProgress, 0.0)
        XCTAssertEqual(coordinator.currentHeaderHeight, 188.0)
        XCTAssertEqual(coordinator.headerTranslationY, 0.0)
        XCTAssertTrue(coordinator.isFullyExpanded)
        XCTAssertFalse(coordinator.isFullyCollapsed)
        XCTAssertEqual(coordinator.activePageIndex, 0)
    }

    func testPartialAndFullCollapseProgression() {
        let coordinator = HeaderCollapseCoordinator(expandedHeight: 188.0, collapsedHeight: 44.0, initialPage: 0)
        // collapseRange is 188 - 44 = 144

        // 1. Partial scroll: 72pt (50% of 144)
        coordinator.updateScrollOffset(72.0, forPage: 0)
        XCTAssertEqual(coordinator.collapseProgress, 0.5, accuracy: 0.001)
        XCTAssertEqual(coordinator.currentHeaderHeight, 188.0 - 72.0, accuracy: 0.001)
        XCTAssertEqual(coordinator.headerTranslationY, -72.0, accuracy: 0.001)
        XCTAssertFalse(coordinator.isFullyCollapsed)
        XCTAssertFalse(coordinator.isFullyExpanded)

        // 2. Full collapse: 144pt
        coordinator.updateScrollOffset(144.0, forPage: 0)
        XCTAssertEqual(coordinator.collapseProgress, 1.0, accuracy: 0.001)
        XCTAssertEqual(coordinator.currentHeaderHeight, 44.0, accuracy: 0.001)
        XCTAssertTrue(coordinator.isFullyCollapsed)

        // 3. Beyond collapse threshold: 300pt
        // Residual page scroll offset is 300 - 144 = 156
        coordinator.updateScrollOffset(300.0, forPage: 0)
        XCTAssertEqual(coordinator.collapseProgress, 1.0, accuracy: 0.001)
        XCTAssertEqual(coordinator.pageScrollOffsets[0], 156.0)
    }

    func testPageSwitchingPreservesHeaderCollapse() {
        let coordinator = HeaderCollapseCoordinator(expandedHeight: 188.0, collapsedHeight: 0.0, initialPage: 0)

        // Page 0 scrolls down 250pt (188pt header collapse + 62pt residual page depth)
        coordinator.updateScrollOffset(250.0, forPage: 0)
        XCTAssertTrue(coordinator.isFullyCollapsed)
        XCTAssertEqual(coordinator.pageScrollOffsets[0], 62.0)

        // User switches to Page 1 (which hasn't been scrolled yet)
        let page1InitialOffset = coordinator.selectPage(1)
        XCTAssertEqual(coordinator.activePageIndex, 1)

        // Header MUST NOT snap open: collapse progress remains 1.0
        XCTAssertTrue(coordinator.isFullyCollapsed)
        // Page 1's starting offset accounts for the collapsed header boundary (188pt)
        XCTAssertEqual(page1InitialOffset, 188.0)

        // User scrolls Page 1 deeper to 400pt (188pt + 212pt)
        coordinator.updateScrollOffset(400.0, forPage: 1)
        XCTAssertEqual(coordinator.pageScrollOffsets[1], 212.0)

        // User switches back to Page 0
        let page0RestoredOffset = coordinator.selectPage(0)
        XCTAssertEqual(coordinator.activePageIndex, 0)
        // Page 0 restores its previous scroll depth (188 + 62 = 250pt)
        XCTAssertEqual(page0RestoredOffset, 250.0)
    }

    func testProgrammaticExpandAndCollapse() {
        let coordinator = HeaderCollapseCoordinator(expandedHeight: 188.0, collapsedHeight: 0.0)

        coordinator.collapseHeader()
        XCTAssertTrue(coordinator.isFullyCollapsed)
        XCTAssertEqual(coordinator.currentHeaderHeight, 0.0)

        coordinator.expandHeader()
        XCTAssertTrue(coordinator.isFullyExpanded)
        XCTAssertEqual(coordinator.currentHeaderHeight, 188.0)

        coordinator.setCollapseProgress(0.25)
        XCTAssertEqual(coordinator.collapseProgress, 0.25)
        XCTAssertEqual(coordinator.currentHeaderHeight, 141.0)
    }
}
