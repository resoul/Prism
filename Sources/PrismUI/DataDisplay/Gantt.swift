import PrismCore

public struct Gantt: Component {
    public let model: GanttModel; public var label: String?
    public init(_ label: String? = nil, model: GanttModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Gantt (\(model.tasks.count))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "grid", "taskCount": String(model.tasks.count), "zoom": String(model.zoom)]; return element }
}
