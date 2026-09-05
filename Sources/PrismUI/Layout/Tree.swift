import PrismCore

public struct Tree<ID: Hashable & Sendable>: Component {
    public let nodes: [TreeNode<ID>]; public var label: String?
    public init(_ label: String? = nil, nodes: [TreeNode<ID>]) { self.label = label; self.nodes = nodes }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Tree (\(nodes.count))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "tree", "nodeCount": String(nodes.count), "maxLevel": String(nodes.map(\.level).max() ?? 0)]; return element }
}
