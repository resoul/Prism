import XCTest
@testable import PrismCore
@testable import PrismUI

final class ResourceTests: XCTestCase {

    @MainActor
    func testResourceRendersLoadingPlaceholderWhenNilPrevious() {
        let loadable: Loadable<String> = .loading(previous: nil)
        let resource = Resource(loadable) { text in
            Text(text).render()
        }

        let element = resource.render()
        XCTAssertEqual(element.props.accessibilityLabel, "Loading")
        XCTAssertEqual(element.props.custom["accessibilityTraits"], String(AccessibilityTraits.updatesFrequently.rawValue))
    }

    @MainActor
    func testResourceRendersDimmedContentOnLoadingWithPrevious() {
        let loadable: Loadable<String> = .loading(previous: "Stale Text")
        let resource = Resource(loadable) { text in
            Text(text).render()
        }

        let element = resource.render()
        XCTAssertEqual(element.resolvedStyle.opacity, 0.6)
        XCTAssertEqual(element.props.custom["accessibilityHint"], "Reloading content")
    }

    @MainActor
    func testResourceRendersLoadedValue() {
        let loadable: Loadable<String> = .loaded("Success Content")
        let resource = Resource(loadable) { text in
            Text(text).testID("content-label")
        }

        let element = resource.render()
        XCTAssertEqual(element.props.testID, "content-label")
        if case .text(let str) = element.kind {
            XCTAssertEqual(str, "Success Content")
        } else {
            XCTFail("Expected text element kind")
        }
    }

    @MainActor
    func testResourceRendersLoadedValueOnRefreshing() {
        let loadable: Loadable<String> = .refreshing(previous: "Refreshing Content")
        let resource = Resource(loadable) { text in
            Text(text).testID("content-label")
        }

        let element = resource.render()
        XCTAssertEqual(element.props.testID, "content-label")
        if case .text(let str) = element.kind {
            XCTAssertEqual(str, "Refreshing Content")
        } else {
            XCTFail("Expected text element kind")
        }
    }

    @MainActor
    func testResourceRendersDefaultFailureWithRetry() {
        let box = RetryBox()
        let error = LoadableError(code: .network, message: "Network unavailable")
        let loadable: Loadable<String> = .failure(error: error, previous: nil)

        let resource = Resource(loadable, retry: { box.setRetried() }) { text in
            Text(text).render()
        }

        let element = resource.render()
        XCTAssertEqual(element.props.accessibilityLabel, "Error: Network unavailable")
        // Check that retry button exists among children
        let retryButton = element.children.first(where: { $0.props.custom["title"] == "Retry" })
        XCTAssertNotNil(retryButton)
    }

    @MainActor
    func testResourceRendersCustomFailureBuilder() {
        let error = LoadableError(code: .unauthorized, message: "Please log in")
        let loadable: Loadable<String> = .failure(error: error, previous: nil)

        let resource = Resource(
            loadable,
            failure: { err, retry in
                Text("Custom: \(err.message)").testID("custom-error")
            }
        ) { text in
            Text(text).render()
        }

        let element = resource.render()
        XCTAssertEqual(element.props.testID, "custom-error")
        if case .text(let str) = element.kind {
            XCTAssertEqual(str, "Custom: Please log in")
        } else {
            XCTFail("Expected custom error text")
        }
    }

    @MainActor
    func testResourceRendersEmptyBuilderOnIdle() {
        let loadable: Loadable<String> = .idle

        let resource = Resource(
            loadable,
            empty: {
                Text("Nothing to display yet").testID("empty-view")
            }
        ) { text in
            Text(text).render()
        }

        let element = resource.render()
        XCTAssertEqual(element.props.testID, "empty-view")
    }
}

private final class RetryBox: @unchecked Sendable {
    var retried = false
    func setRetried() { retried = true }
}
