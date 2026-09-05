import PrismCore

public struct CommandPalette: Component {
    public let snapshot: CommandPaletteSnapshot; public var label: String?
    public init(_ label: String? = nil, snapshot: CommandPaletteSnapshot = CommandPaletteSnapshot()) { self.label = label; self.snapshot = snapshot }
    public func body(context: ComponentContext) -> RenderElement { var element = Text(snapshot.query.isEmpty ? "Command palette" : snapshot.query).render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "dialog", "query": snapshot.query, "resultCount": String(snapshot.results.count), "isPresented": snapshot.isPresented ? "true" : "false", "isLoading": snapshot.isLoading ? "true" : "false"]; return element }
}
