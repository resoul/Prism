import Foundation
import PrismCore

public struct BreadcrumbItem: Hashable, Sendable { public let title: String; public let path: String?; public init(_ title: String, path: String? = nil) { self.title = title; self.path = path } }
public struct Breadcrumb: Component {
    public let items: [BreadcrumbItem]; public let navigator: Navigator?
    public init(_ items: [BreadcrumbItem], navigator: Navigator? = nil) { self.items = items; self.navigator = navigator }
    public func activate(_ item: BreadcrumbItem) { if let path = item.path { navigator?.push(path) } }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 6) { for (index, item) in items.enumerated() { Text(item.title); if index < items.count - 1 { Text("/") } } }.render(in: context)
        element.props.custom = ["role": "navigation", "control": "breadcrumb", "count": String(items.count)]
        element.props.accessibilityLabel = "Breadcrumb"
        return element
    }
}

public struct Pagination: Component {
    public let page: Binding<Int>; public let pageCount: Int; public var label: String?
    public init(page: Binding<Int>, pageCount: Int, label: String? = nil) { self.page = page; self.pageCount = max(1, pageCount); self.label = label }
    public func go(to proposed: Int) { page.setIfChanged(min(max(proposed, 1), pageCount)) }
    public func next() { go(to: page.wrappedValue + 1) }; public func previous() { go(to: page.wrappedValue - 1) }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 8) { Text("‹"); Text("\(page.wrappedValue) / \(pageCount)"); Text("›") }.render(in: context)
        element.props.accessibilityLabel = label ?? "Pagination"
        element.props.custom = ["role": "navigation", "page": String(page.wrappedValue), "pageCount": String(pageCount)]
        return element
    }
}

public struct NavigationMenuItem: Hashable, Sendable { public let id: String; public let title: String; public let path: String?; public let shortcut: KeyboardShortcut?; public init(id: String, title: String, path: String? = nil, shortcut: KeyboardShortcut? = nil) { self.id = id; self.title = title; self.path = path; self.shortcut = shortcut } }
public struct NavigationMenu: Component {
    public let items: [NavigationMenuItem]; public let selection: Binding<String>; public let navigator: Navigator?
    public init(items: [NavigationMenuItem], selection: Binding<String>, navigator: Navigator? = nil) { self.items = items; self.selection = selection; self.navigator = navigator }
    public func activate(_ item: NavigationMenuItem) { selection.setIfChanged(item.id); if let path = item.path { navigator?.push(path) } }
    public func body(context: ComponentContext) -> RenderElement {
        var element = HStack(spacing: 12) { for item in items { Text(item.title).background(item.id == selection.wrappedValue ? Color.hex("#DBEAFE") : .clear) } }.render(in: context)
        element.props.custom = ["role": "navigation", "control": "navigationMenu", "selectedID": selection.wrappedValue]
        element.props.accessibilityLabel = "Navigation menu"
        return element
    }
}
