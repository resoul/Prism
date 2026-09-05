import PrismCore

/// Experimental Menubar semantic facade; native menu adapters remain host-owned.
public struct Menubar: Component {
    public let model: MenubarModel; public var label: String?
    public init(_ label: String? = nil, model: MenubarModel) { self.label = label; self.model = model }
    public func body(context: ComponentContext) -> RenderElement { var element = HStack { Text("Menu") }.render(in: context); element.props.accessibilityLabel = label; element.props.custom = ["role": "menubar", "menuCount": String(model.menus.count), "isOpen": model.menuIndex == nil ? "false" : "true"]; return element }
}
