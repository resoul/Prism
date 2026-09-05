import Foundation

public struct TreeNode<ID: Hashable & Sendable>: Sendable, Equatable {
    public let id: ID; public let title: String; public let parentID: ID?; public let level: Int; public var hasChildren: Bool
    public init(id: ID, title: String, parentID: ID? = nil, level: Int = 0, hasChildren: Bool = false) { self.id = id; self.title = title; self.parentID = parentID; self.level = level; self.hasChildren = hasChildren }
}

public struct TreeModel<ID: Hashable & Sendable>: Sendable, Equatable {
    public var nodes: [ID: TreeNode<ID>]; public private(set) var roots: [ID]; public private(set) var expanded: Set<ID>
    public init(nodes: [TreeNode<ID>], roots: [ID]) { self.nodes = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) }); self.roots = roots; self.expanded = [] }
    public mutating func toggle(_ id: ID) { guard nodes[id]?.hasChildren == true else { return }; if !expanded.insert(id).inserted { expanded.remove(id) } }
    public mutating func collapseAll() { expanded.removeAll() }
    public func visibleNodes(offset: Int = 0, limit: Int = .max) -> [TreeNode<ID>] { var output: [TreeNode<ID>] = []; func visit(_ id: ID) { guard output.count < offset + limit, let node = nodes[id] else { return }; if output.count >= offset { output.append(node) }; guard expanded.contains(id) else { return }; nodes.values.filter { $0.parentID == id }.sorted { String(describing: $0.id) < String(describing: $1.id) }.forEach { visit($0.id) } }; roots.forEach(visit); return Array(output.dropFirst(min(offset, output.count))) }
}

public actor LazyTreeLoader<ID: Hashable & Sendable> {
    public typealias Provider = @Sendable (ID) async throws -> [TreeNode<ID>]
    private let provider: Provider; private var tasks: [ID: Task<Void, Never>] = [:]; private(set) var model: TreeModel<ID>
    public init(model: TreeModel<ID>, provider: @escaping Provider) { self.model = model; self.provider = provider }
    public func snapshot() -> TreeModel<ID> { model }
    public func loadChildren(for id: ID) { tasks[id]?.cancel(); tasks[id] = Task { [weak self] in do { let children = try await provider(id); guard !Task.isCancelled else { return }; await self?.apply(children, parent: id) } catch {} } }
    public func cancelLoading(for id: ID) { tasks[id]?.cancel(); tasks[id] = nil }
    private func apply(_ children: [TreeNode<ID>], parent: ID) { for child in children { model.nodes[child.id] = child }; model.nodes[parent]?.hasChildren = !children.isEmpty; tasks[parent] = nil }
}
