import Foundation
import PrismCore

public enum DrawerEdge: String, Sendable { case leading, trailing, bottom }

private func overlaySurface(
    type: String, title: String?, isPresented: Bool, layer: OverlayLayer,
    role: String, modal: Bool, content: [RenderElement], context: ComponentContext,
    placement: String? = nil
) -> RenderElement {
    guard isPresented else { return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty) }
    var props = ElementProps(accessibilityLabel: title)
    props.custom = ["role": role, "modal": modal ? "true" : "false", "overlayType": type]
    if let placement { props.custom["placement"] = placement }
    var children: [RenderElement] = []
    if let title { children.append(Text(title).font(.heading).render(in: context)) }
    children.append(contentsOf: content)
    return RenderElement(id: ElementID(typeName: type), kind: .stack(axis: .vertical, alignment: .stretch, spacing: 12), props: props, modifiers: [.padding(.init(top: 16, leading: 16, bottom: 16, trailing: 16)), .background(context.theme?.colors.background ?? .white), .testID("\(type)_surface")], children: children).portal(layer: layer)
}

/// Confirmation-only modal with explicit cancel/confirm actions.
public struct AlertDialog: Component {
    public let isPresented: Bool; public let title: String; public let message: String?; public let onDismiss: @Sendable () -> Void; public let onConfirm: @Sendable () -> Void
    public init(isPresented: Binding<Bool>, title: String, message: String? = nil, onConfirm: @escaping @Sendable () -> Void) { self.isPresented = isPresented.wrappedValue; self.title = title; self.message = message; self.onDismiss = { isPresented.wrappedValue = false }; self.onConfirm = onConfirm }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "AlertDialog", title: title, isPresented: isPresented, layer: .modal, role: "alertDialog", modal: true, content: message.map { [Text($0).render(in: context)] } ?? [], context: context) }
}

public struct Sheet: Component {
    public let isPresented: Bool; public let title: String?; public let onDismiss: @Sendable () -> Void; public let content: [RenderElement]
    public init(isPresented: Binding<Bool>, title: String? = nil, @ComponentBuilder content: () -> [RenderElement]) { self.isPresented = isPresented.wrappedValue; self.title = title; self.onDismiss = { isPresented.wrappedValue = false }; self.content = content() }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "Sheet", title: title, isPresented: isPresented, layer: .modal, role: "dialog", modal: true, content: content, context: context, placement: "bottom") }
}

public struct Drawer: Component {
    public let isPresented: Bool; public let edge: DrawerEdge; public let title: String?; public let onDismiss: @Sendable () -> Void; public let content: [RenderElement]
    public init(isPresented: Binding<Bool>, edge: DrawerEdge = .trailing, title: String? = nil, @ComponentBuilder content: () -> [RenderElement]) { self.isPresented = isPresented.wrappedValue; self.edge = edge; self.title = title; self.onDismiss = { isPresented.wrappedValue = false }; self.content = content() }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "Drawer", title: title, isPresented: isPresented, layer: .modal, role: "dialog", modal: true, content: content, context: context, placement: edge.rawValue) }
}

public struct Popover: Component {
    public let isPresented: Bool; public let anchorID: String; public let content: [RenderElement]
    public init(isPresented: Binding<Bool>, anchorID: String, @ComponentBuilder content: () -> [RenderElement]) { self.isPresented = isPresented.wrappedValue; self.anchorID = anchorID; self.content = content() }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "Popover", title: nil, isPresented: isPresented, layer: .floating, role: "dialog", modal: false, content: content, context: context, placement: "anchor:\(anchorID)") }
}

public struct DropdownMenuItem: Hashable, Sendable { public let id: String; public let title: String; public let isDestructive: Bool; public init(id: String, title: String, isDestructive: Bool = false) { self.id = id; self.title = title; self.isDestructive = isDestructive } }
public struct DropdownMenu: Component {
    public let isPresented: Bool; public let anchorID: String; public let items: [DropdownMenuItem]; public let onSelect: @Sendable (DropdownMenuItem) -> Void
    public init(isPresented: Binding<Bool>, anchorID: String, items: [DropdownMenuItem], onSelect: @escaping @Sendable (DropdownMenuItem) -> Void = { _ in }) { self.isPresented = isPresented.wrappedValue; self.anchorID = anchorID; self.items = items; self.onSelect = onSelect }
    public func select(_ item: DropdownMenuItem) { onSelect(item) }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "DropdownMenu", title: nil, isPresented: isPresented, layer: .floating, role: "menu", modal: false, content: items.map { Text($0.title).render(in: context) }, context: context, placement: "anchor:\(anchorID)") }
}

public struct ContextMenu: Component {
    public let isPresented: Bool; public let location: CGPoint; public let items: [DropdownMenuItem]; public let onSelect: @Sendable (DropdownMenuItem) -> Void
    public init(isPresented: Binding<Bool>, location: CGPoint, items: [DropdownMenuItem], onSelect: @escaping @Sendable (DropdownMenuItem) -> Void = { _ in }) { self.isPresented = isPresented.wrappedValue; self.location = location; self.items = items; self.onSelect = onSelect }
    public func select(_ item: DropdownMenuItem) { onSelect(item) }
    public func body(context: ComponentContext) -> RenderElement { overlaySurface(type: "ContextMenu", title: nil, isPresented: isPresented, layer: .floating, role: "menu", modal: false, content: items.map { Text($0.title).render(in: context) }, context: context, placement: "\(location.x),\(location.y)") }
}
