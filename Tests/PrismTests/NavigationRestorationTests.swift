import XCTest
import Prism

final class NavigationRestorationTests: XCTestCase {
    func testNavigationStateSaveLoadCycle() async {
        let suite = "test.suite.nav.\(UUID().uuidString)"
        let prefs = Preferences(suiteName: suite)
        let store = PrismStorageNavigationStore(preferences: prefs, keyName: "test.nav.state")

        // Initial state should be nil (empty)
        let initial = await store.loadNavigationState()
        XCTAssertNil(initial)

        // Save a non-empty state
        let entries = [
            RouteEntry(path: "/home"),
            RouteEntry(path: "/profile/42", parameters: ["id": "42"], state: ["tab": "activity"])
        ]
        let state = NavigationState(entries: entries)
        await store.saveNavigationState(state)

        // Load saved state
        let restored = await store.loadNavigationState()
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.entries.count, 2)
        XCTAssertEqual(restored?.current?.path, "/profile/42")
        XCTAssertEqual(restored?.current?.parameters["id"], "42")
        XCTAssertEqual(restored?.current?.state["tab"], "activity")

        // Clear state
        await store.clearNavigationState()
        let cleared = await store.loadNavigationState()
        XCTAssertNil(cleared)
    }
}
