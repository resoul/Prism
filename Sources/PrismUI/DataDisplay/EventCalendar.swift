import PrismCore

public struct EventCalendar: Component {
    public let model: EventCalendarModel; public var label: String?
    public init(_ label: String? = nil, model: EventCalendarModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Event calendar (\(model.events.count))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "grid", "eventCount": String(model.events.count), "layoutCount": String(model.layout().count)]; return element }
}
