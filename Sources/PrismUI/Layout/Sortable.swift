import PrismCore

/// Experimental sortable list semantic facade; host owns drag and autoscroll gestures.
public struct Sortable<ID: Hashable & Sendable>: Component {
    public let ids: [ID]
    public var label: String?
    public var isDisabled: Bool
    public init(_ label: String? = nil, ids: [ID], isDisabled: Bool = false) { self.label = label; self.ids = ids; self.isDisabled = isDisabled }
    public func body(context: ComponentContext) -> RenderElement { var element = Text("Sortable (\(ids.count))").render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "list", "itemCount": String(ids.count), "isDisabled": isDisabled ? "true" : "false"]; return element }
}
