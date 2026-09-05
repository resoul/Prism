import XCTest
@testable import PrismUI
@testable import PrismCore

final class VisualAccessibilityAuditTests: XCTestCase {
    func testCatalogBaselineMatrixIsDeterministicAcrossEnvironmentModes() {
        let store = PrismCatalogStore()
        store.select(id: "button")
        let host = PrismCatalogHost(store: store)
        let modes: [(String, LocalizationEnvironment)] = [
            ("light-large-ltr", LocalizationEnvironment()),
            ("dark-accessibility-rtl", LocalizationEnvironment(locale: Locale(identifier: "ar"), contentSizeCategory: .accessibilityExtraExtraExtraLarge, reduceMotion: true, increaseContrast: true)),
            ("compact-ltr", LocalizationEnvironment(layoutDirection: .leftToRight, contentSizeCategory: .small))
        ]

        var baselines: [String: String] = [:]
        for (name, environment) in modes {
            let first = host.render(in: ComponentContext(environment: environment)).dumpTree()
            let second = host.render(in: ComponentContext(environment: environment)).dumpTree()
            XCTAssertEqual(first, second, "baseline \(name) must be deterministic")
            XCTAssertTrue(first.contains("catalog.inspectors"))
            XCTAssertTrue(first.contains("catalog.example.button"))
            baselines[name] = first
        }
        XCTAssertEqual(Set(baselines.keys), Set(modes.map(\.0)))
    }

    @MainActor
    func testAccessibilityActionChangesStateAndStaleElementCannotAct() {
        var activated = false
        let element = AccessibilityElement(
            id: ElementID(typeName: "CatalogAction"),
            label: "Activate example",
            traits: .button,
            actions: [.activate { activated = true }],
            testID: "catalog.example.action"
        )
        XCTAssertTrue(element.performAction(.activate))
        XCTAssertTrue(activated)
        element.invalidate()
        XCTAssertFalse(element.performAction(.activate))
    }
}
