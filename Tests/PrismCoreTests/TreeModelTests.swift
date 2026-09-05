import XCTest
@testable import PrismCore

final class TreeModelTests: XCTestCase {
    func testExpandCollapseAndVirtualizedRows() {
        let root = TreeNode(id: 0, title: "Root", level: 0, hasChildren: true); let child = TreeNode(id: 1, title: "Child", parentID: 0, level: 1)
        var model = TreeModel(nodes: [root, child], roots: [0]); XCTAssertEqual(model.visibleNodes().map(\.id), [0]); model.toggle(0); XCTAssertEqual(model.visibleNodes().map(\.id), [0, 1]); model.collapseAll(); XCTAssertEqual(model.visibleNodes(offset: 0, limit: 1).count, 1)
    }
    func testLazyLoadingCancellationAndChangedAncestry() async throws {
        let root = TreeNode(id: "root", title: "Root", level: 0, hasChildren: true); let loader = LazyTreeLoader(model: TreeModel(nodes: [root], roots: ["root"])) { id in try await Task.sleep(nanoseconds: 1_000_000); return [TreeNode(id: "child", title: "Child", parentID: id, level: 1)] }
        await loader.loadChildren(for: "root"); try await Task.sleep(nanoseconds: 20_000_000)
        let snapshot = await loader.snapshot(); XCTAssertNotNil(snapshot.nodes["child"])
        await loader.loadChildren(for: "root"); await loader.cancelLoading(for: "root")
    }
}
