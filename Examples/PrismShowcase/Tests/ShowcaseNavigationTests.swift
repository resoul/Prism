import XCTest
import PrismCore
import PrismUI

@MainActor
final class ShowcaseNavigationTests: XCTestCase {

    func testAllSevenCategoriesExistWithStableIDsAndTitles() {
        let categories = ShowcaseCategory.allCases
        XCTAssertEqual(categories.count, 7, "Showcase contract mandates exactly 7 categories")

        let expectedIDs = [
            "foundations",
            "data-display",
            "forms",
            "feedback-overlays",
            "navigation",
            "layout-collections",
            "advanced-data"
        ]
        XCTAssertEqual(categories.map(\.rawValue), expectedIDs)

        XCTAssertEqual(ShowcaseCategory.foundations.title, "Foundations")
        XCTAssertEqual(ShowcaseCategory.dataDisplay.title, "Data Display")
        XCTAssertEqual(ShowcaseCategory.forms.title, "Forms")
        XCTAssertEqual(ShowcaseCategory.feedbackAndOverlays.title, "Feedback & Overlays")
        XCTAssertEqual(ShowcaseCategory.navigation.title, "Navigation")
        XCTAssertEqual(ShowcaseCategory.layoutAndCollections.title, "Layout & Collections")
        XCTAssertEqual(ShowcaseCategory.advancedData.title, "Advanced Data")
    }

    func testCategoryCountsComputedFromRegistry() {
        for category in ShowcaseCategory.allCases {
            let count = ShowcaseRegistry.categoryCount(for: category)
            let items = ShowcaseRegistry.items(for: category)
            XCTAssertEqual(count, items.count)
            XCTAssertGreaterThan(count, 0, "Category \(category.rawValue) must have registered components")
        }

        XCTAssertEqual(ShowcaseRegistry.allItems.count, ShowcaseCategory.allCases.reduce(0) { $0 + ShowcaseRegistry.categoryCount(for: $1) })
    }

    func testRouteParsingAndDeepLinking() {
        XCTAssertEqual(ShowcaseRoute.parse(path: "welcome"), .welcome)
        XCTAssertEqual(ShowcaseRoute.parse(path: ""), .welcome)
        XCTAssertEqual(ShowcaseRoute.parse(path: "categories"), .categories)
        XCTAssertEqual(ShowcaseRoute.parse(path: "category/forms"), .category(.forms))
        XCTAssertEqual(ShowcaseRoute.parse(path: "forms"), .category(.forms))
        XCTAssertEqual(ShowcaseRoute.parse(path: "component/counter"), .component(id: "counter"))
        XCTAssertEqual(ShowcaseRoute.parse(path: "counter"), .component(id: "counter"))
        XCTAssertEqual(ShowcaseRoute.parse(path: "component/button"), .component(id: "button"))
        XCTAssertEqual(ShowcaseRoute.parse(path: "component/unknown_xyz"), .notFound(id: "unknown_xyz"))
        XCTAssertEqual(ShowcaseRoute.parse(path: "invalid_path_404"), .notFound(id: "invalid_path_404"))
    }

    func testSequentialNavigationAndBackStack() {
        let store = ShowcaseStore(initialState: ShowcaseState())
        XCTAssertEqual(store.currentRoute, .welcome)
        XCTAssertEqual(store.state.navigation.routeStack.count, 1)

        store.navigate(to: .categories)
        XCTAssertEqual(store.currentRoute, .categories)
        XCTAssertEqual(store.state.navigation.routeStack.count, 2)

        store.selectCategory(.forms)
        XCTAssertEqual(store.currentRoute, .category(.forms))
        XCTAssertEqual(store.state.navigation.selectedCategory, .forms)
        XCTAssertEqual(store.state.navigation.routeStack.count, 3)

        store.selectComponent("counter")
        XCTAssertEqual(store.currentRoute, .component(id: "counter"))
        XCTAssertEqual(store.state.navigation.selectedComponentID, "counter")
        XCTAssertEqual(store.state.navigation.routeStack.count, 4)

        // Pop back to category
        store.pop()
        XCTAssertEqual(store.currentRoute, .category(.forms))
        XCTAssertEqual(store.state.navigation.routeStack.count, 3)

        // Pop back to categories list
        store.pop()
        XCTAssertEqual(store.currentRoute, .categories)
        XCTAssertEqual(store.state.navigation.routeStack.count, 2)

        // Pop back to welcome
        store.pop()
        XCTAssertEqual(store.currentRoute, .welcome)
        XCTAssertEqual(store.state.navigation.routeStack.count, 1)

        // Popping at root is a no-op and does not crash
        store.pop()
        XCTAssertEqual(store.currentRoute, .welcome)
        XCTAssertEqual(store.state.navigation.routeStack.count, 1)
    }

    func testRapidTapsDoNotDuplicateRoutes() {
        let store = ShowcaseStore(initialState: ShowcaseState())
        XCTAssertEqual(store.state.navigation.routeStack.count, 1)

        // Rapidly tap the same target
        store.navigate(to: .categories)
        store.navigate(to: .categories)
        store.navigate(to: .categories)

        XCTAssertEqual(store.currentRoute, .categories)
        XCTAssertEqual(store.state.navigation.routeStack.count, 2, "Rapid taps to same route must not duplicate stack")
    }

    func testSearchFilteringAndClearing() {
        let store = ShowcaseStore(initialState: ShowcaseState())

        store.setSearchQuery("Button")
        XCTAssertEqual(store.state.navigation.searchQuery, "Button")

        let results = ShowcaseRegistry.search(query: "Button")
        XCTAssertTrue(results.contains(where: { $0.id == "button" }))

        let emptyResults = ShowcaseRegistry.search(query: "nonexistent_term_9999")
        XCTAssertTrue(emptyResults.isEmpty)

        store.clearSearch()
        XCTAssertTrue(store.state.navigation.searchQuery.isEmpty)
    }

    func testInvalidRouteShowsRecoverableNotFound() {
        let store = ShowcaseStore(initialState: ShowcaseState())

        store.selectComponent("nonexistent_widget_123")
        XCTAssertEqual(store.currentRoute, .notFound(id: "nonexistent_widget_123"))

        // Recover by navigating back to categories
        store.navigate(to: .categories)
        XCTAssertEqual(store.currentRoute, .categories)
    }

    func testThemeChangePreservesNavigationState() {
        let store = ShowcaseStore(initialState: ShowcaseState())
        store.navigate(to: .component(id: "counter"))
        XCTAssertEqual(store.currentRoute, .component(id: "counter"))

        store.selectTheme(.forest)
        XCTAssertEqual(store.activeThemeID, .forest)
        XCTAssertEqual(store.currentRoute, .component(id: "counter"), "Theme change must not reset current route")
    }

    func testContainerWidthUpdatesBreakpoint() {
        let store = ShowcaseStore(initialState: ShowcaseState())

        store.setContainerWidth(375)
        XCTAssertEqual(store.state.navigation.breakpoint, .compact)
        XCTAssertTrue(store.state.navigation.breakpoint.isCompact)

        store.setContainerWidth(768)
        XCTAssertEqual(store.state.navigation.breakpoint, .medium)
        XCTAssertTrue(store.state.navigation.breakpoint.isMedium)

        store.setContainerWidth(1024)
        XCTAssertEqual(store.state.navigation.breakpoint, .expanded)

        store.setContainerWidth(1440)
        XCTAssertEqual(store.state.navigation.breakpoint, .wide)

        // Route state is preserved across resize
        XCTAssertEqual(store.currentRoute, .welcome)
    }

    func testRootElementRendersAcrossAllRoutes() {
        let store = ShowcaseStore(initialState: ShowcaseState())

        // Welcome
        let welcomeElement = store.rootElement()
        XCTAssertNotNil(welcomeElement)

        // Categories
        store.navigate(to: .categories)
        let categoriesElement = store.rootElement()
        XCTAssertNotNil(categoriesElement)

        // Category
        store.selectCategory(.forms)
        let categoryElement = store.rootElement()
        XCTAssertNotNil(categoryElement)

        // Component
        store.selectComponent("counter")
        let detailElement = store.rootElement()
        XCTAssertNotNil(detailElement)

        // Not Found
        store.navigate(to: .notFound(id: "fake_id"))
        let notFoundElement = store.rootElement()
        XCTAssertNotNil(notFoundElement)
    }
}
