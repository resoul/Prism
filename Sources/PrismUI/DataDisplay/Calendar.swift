import PrismCore

public struct CalendarView: Component {
    public let layout: CalendarLayout; public var label: String?
    public init(_ label: String? = nil, layout: CalendarLayout) { self.label = label; self.layout = layout }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Calendar (\(layout.mode.rawValue))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "calendar", "mode": layout.mode.rawValue, "cellCount": String(layout.cells.count), "weekdayCount": String(layout.weekdaySymbols.count), "isRTL": layout.isRTL ? "true" : "false"]; return element }
}
