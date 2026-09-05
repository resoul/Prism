import XCTest
@testable import PrismUI

final class CatalogReleaseTests: XCTestCase {
    func testCatalogHasIsolatedEntryAndStateMatrixForEveryPublicTier() {
        XCTAssertGreaterThanOrEqual(PrismCatalog.entries(tier: .p0).count, 8)
        XCTAssertGreaterThanOrEqual(PrismCatalog.entries(tier: .p1).count, 20)
        XCTAssertGreaterThanOrEqual(PrismCatalog.entries(tier: .p2).count, 30)
        XCTAssertTrue(PrismCatalog.entries.allSatisfy { !$0.states.isEmpty && !$0.documentationPath.isEmpty })
        XCTAssertEqual(Set(PrismCatalog.entries.map(\.id)).count, PrismCatalog.entries.count)
    }

    func testCatalogScreenExposesDeveloperControls() {
        let element = PrismCatalogScreen(tier: .p2, contentSize: .accessibilityLarge, reduceMotion: true).render()
        XCTAssertEqual(element.props.custom["catalogTier"], "p2")
        XCTAssertEqual(element.props.custom["reduceMotion"], "true")
        XCTAssertFalse(element.children.isEmpty)
    }

    func testAccessibilityAuditFixtureBuilds() {
        XCTAssertFalse(AccessibilityAuditScreen().render().children.isEmpty)
    }

    func testHostPersistsSelectionAndControlsAcrossRebuild() {
        let store = PrismCatalogStore()
        let host = PrismCatalogHost(store: store)

        let initial = host.render()
        XCTAssertEqual(initial.props.custom["selectedEntry"], "")

        store.select(id: "button")
        store.setTheme("dark")
        store.toggleReduceMotion()
        store.toggleHighContrast()

        let rebuilt = host.render()
        XCTAssertEqual(rebuilt.props.custom["selectedEntry"], "button")
        XCTAssertEqual(rebuilt.props.custom["theme"], "dark")
        XCTAssertEqual(rebuilt.props.custom["reduceMotion"], "true")
        XCTAssertEqual(rebuilt.props.custom["highContrast"], "true")
        XCTAssertEqual(rebuilt.props.custom["interactionCount"], "4")
        XCTAssertFalse(rebuilt.children.isEmpty)
    }

    func testHostTierFilterAndSelectionAreStable() {
        let store = PrismCatalogStore(tier: .p2)
        store.select(id: "accordion")
        let element = PrismCatalogHost(store: store).render()
        XCTAssertEqual(element.props.custom["catalogTier"], "p2")
        XCTAssertEqual(element.props.custom["selectedEntry"], "accordion")
        XCTAssertEqual(store.selectedEntry()?.component, "Accordion")
    }
}
