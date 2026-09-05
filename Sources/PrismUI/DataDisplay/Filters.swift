import PrismCore

public struct FilterEditor: Component {
    public let model: FilterModel; public var label: String?
    public init(_ label: String? = nil, model: FilterModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Filters").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "group", "schemaVersion": String(model.schemaVersion)]; return element }
}
