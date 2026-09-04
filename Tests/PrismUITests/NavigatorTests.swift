import XCTest
import Foundation
@testable import PrismUI

final class NavigatorTests: XCTestCase {

    private struct DummyScreen: Screen {
        let title: String?
        func body(context: ComponentContext) -> RenderElement {
            Text("Dummy").render(in: context)
        }
    }

    func testStackPushPopAndReplace() {
        let nav = Navigator(initialPath: "/feed")
        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/feed")
        XCTAssertFalse(nav.canPop)

        // Push
        nav.push("/detail", parameters: ["id": "100"])
        XCTAssertEqual(nav.depth, 2)
        XCTAssertEqual(nav.currentEntry?.path, "/detail")
        XCTAssertEqual(nav.currentEntry?.parameters["id"], "100")
        XCTAssertTrue(nav.canPop)

        // Replace
        nav.replace("/comments")
        XCTAssertEqual(nav.depth, 2)
        XCTAssertEqual(nav.currentEntry?.path, "/comments")

        // Pop
        let popped = nav.pop()
        XCTAssertTrue(popped)
        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/feed")
        XCTAssertFalse(nav.canPop)
    }

    func testRootPopBoundarySafety() {
        let nav = Navigator(initialPath: "/home")
        XCTAssertEqual(nav.depth, 1)

        // Popping at root must be a safe no-op returning false
        let popped = nav.pop()
        XCTAssertFalse(popped)
        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/home")
    }

    func testReset() {
        let nav = Navigator(initialPath: "/1")
        nav.push("/2")
        nav.push("/3")
        XCTAssertEqual(nav.depth, 3)

        nav.reset(to: "/login")
        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/login")
        XCTAssertFalse(nav.canPop)
    }

    func testStateRestorationValidRoutes() {
        let router = Router(routes: [
            Route("/home") { _ in DummyScreen(title: "Home") },
            Route("/profile/:id") { _ in DummyScreen(title: "Profile") }
        ])

        let saved = NavigationState(version: 1, entries: [
            RouteEntry(path: "/home"),
            RouteEntry(path: "/profile/42", parameters: ["id": "42"])
        ])

        let nav = Navigator(initialPath: "/loading")
        nav.restore(from: saved, router: router)

        XCTAssertEqual(nav.depth, 2)
        XCTAssertEqual(nav.currentEntry?.path, "/profile/42")
    }

    func testStateRestorationDropsInvalidRoutes() {
        let router = Router(routes: [
            Route("/home") { _ in DummyScreen(title: "Home") }
        ])

        let saved = NavigationState(version: 1, entries: [
            RouteEntry(path: "/home"),
            RouteEntry(path: "/obsolete/screen")
        ])

        let nav = Navigator(initialPath: "/init")
        nav.restore(from: saved, router: router)

        // Obsolete route dropped; only /home kept
        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/home")
    }

    func testStateRestorationVersionMismatchResetsToFallback() {
        let router = Router(routes: [
            Route("/home") { _ in DummyScreen(title: "Home") }
        ])

        let outdatedState = NavigationState(version: 999, entries: [
            RouteEntry(path: "/home")
        ])

        let nav = Navigator(initialPath: "/init")
        nav.restore(from: outdatedState, router: router, fallbackPath: "/home")

        XCTAssertEqual(nav.depth, 1)
        XCTAssertEqual(nav.currentEntry?.path, "/home")
    }

    func testFluxObservationOnNavigation() async {
        let nav = Navigator(initialPath: "/step1")
        let expectation = expectation(description: "Emitted stack mutation")

        var states: [NavigationState] = []
        let task = Task {
            for await st in nav.stateFlux.stream {
                states.append(st)
                if states.count == 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        nav.push("/step2")
        nav.push("/step3")

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states[0].current?.path, "/step2")
        XCTAssertEqual(states[1].current?.path, "/step3")
    }
}
