import XCTest
import Foundation
@testable import PrismUI

final class RouterTests: XCTestCase {

    private struct TestScreen: Screen {
        let title: String?
        let path: String

        func body(context: ComponentContext) -> RenderElement {
            Text(title ?? path).render(in: context)
        }
    }

    func testStaticSegmentMatching() {
        let router = Router(routes: [
            Route("/home") { _ in TestScreen(title: "Home", path: "/home") },
            Route("/settings/privacy") { _ in TestScreen(title: "Privacy", path: "/settings/privacy") }
        ])

        let homeMatch = router.resolve(path: "/home")
        XCTAssertNotNil(homeMatch)
        XCTAssertEqual(homeMatch?.screen.title, "Home")

        let privacyMatch = router.resolve(path: "/settings/privacy")
        XCTAssertNotNil(privacyMatch)
        XCTAssertEqual(privacyMatch?.screen.title, "Privacy")

        let miss = router.resolve(path: "/unknown")
        XCTAssertNil(miss)
    }

    func testDynamicParametersExtraction() {
        let router = Router(routes: [
            Route("/users/:userId/posts/:postId") { params in
                let u = params.required("userId")
                let p = params.required("postId")
                return TestScreen(title: "User \(u) Post \(p)", path: "/users/\(u)/posts/\(p)")
            }
        ])

        let match = router.resolve(path: "/users/42/posts/999")
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.screen.title, "User 42 Post 999")
        XCTAssertEqual(match?.parameters["userId"], "42")
        XCTAssertEqual(match?.parameters["postId"], "999")
    }

    func testWildcardRoute() {
        let router = Router(routes: [
            Route("/docs/*") { _ in TestScreen(title: "Docs", path: "/docs") }
        ])

        let match1 = router.resolve(path: "/docs/api/v1/auth")
        XCTAssertNotNil(match1)
        XCTAssertEqual(match1?.screen.title, "Docs")

        let match2 = router.resolve(path: "/docs")
        XCTAssertNotNil(match2)
    }

    func testQueryParametersExtraction() {
        let router = Router(routes: [
            Route("/search") { params in
                let q = params.query("q") ?? ""
                let page = params.query("page") ?? "1"
                return TestScreen(title: "Search \(q) p\(page)", path: "/search")
            }
        ])

        let match = router.resolve(path: "/search?q=prism%20ui&page=3")
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.parameters.query("q"), "prism ui")
        XCTAssertEqual(match?.parameters.query("page"), "3")
        XCTAssertEqual(match?.screen.title, "Search prism ui p3")
    }

    func testDeepLinkResolverCustomScheme() {
        let url = URL(string: "prism://profile/alex?tab=activity")!
        let path = DeepLinkResolver.path(from: url)
        XCTAssertEqual(path, "/profile/alex?tab=activity")

        let router = Router(routes: [
            Route("/profile/:name") { params in
                let n = params.required("name")
                let t = params.query("tab") ?? "overview"
                return TestScreen(title: "\(n) - \(t)", path: "/profile/\(n)")
            }
        ])

        let match = router.resolve(url: url)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.parameters.required("name"), "alex")
        XCTAssertEqual(match?.parameters.query("tab"), "activity")
        XCTAssertEqual(match?.screen.title, "alex - activity")
    }

    func testDeepLinkResolverUniversalLink() {
        let url = URL(string: "https://app.prism.design/articles/123")!
        let path = DeepLinkResolver.path(from: url)
        XCTAssertEqual(path, "/articles/123")
    }

    func testPathNormalization() {
        XCTAssertEqual(DeepLinkResolver.normalizePath("home"), "/home")
        XCTAssertEqual(DeepLinkResolver.normalizePath("/home/"), "/home")
        XCTAssertEqual(DeepLinkResolver.normalizePath("//users///42/"), "/users/42")
        XCTAssertEqual(DeepLinkResolver.normalizePath("/search/?q=1"), "/search?q=1")
    }

    func testNotFoundFallbackHandler() {
        let router = Router(routes: [
            Route("/home") { _ in TestScreen(title: "Home", path: "/home") }
        ])
        router.setNotFoundHandler { path in
            TestScreen(title: "Custom 404: \(path)", path: path)
        }

        let match = router.resolve(path: "/missing/endpoint")
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.screen.title, "Custom 404: /missing/endpoint")
    }
}
