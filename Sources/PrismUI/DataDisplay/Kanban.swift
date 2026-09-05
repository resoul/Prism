import PrismCore

public struct Kanban: Component {
    public let model: KanbanModel; public var label: String?
    public init(_ label: String? = nil, model: KanbanModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Kanban (\(model.columns.count))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "list", "columnCount": String(model.columns.count), "cardCount": String(model.cards.count), "isMoving": model.isMoving ? "true" : "false"]; return element }
}
