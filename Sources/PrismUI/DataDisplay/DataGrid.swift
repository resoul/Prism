import PrismCore

public struct DataGrid: Component {
    public let viewport: DataGridViewport; public var label: String?
    public init(_ label: String? = nil, viewport: DataGridViewport) { self.label = label; self.viewport = viewport }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Data grid").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "grid", "rows": String(viewport.rows), "columns": String(viewport.columns), "mountedCells": String(viewport.mountedCells.count), "anchor": "\(viewport.scrollAnchor.row),\(viewport.scrollAnchor.column)"]; return element }
}
