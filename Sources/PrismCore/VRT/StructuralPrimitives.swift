import Foundation

/// Structural grouping primitive that inlines its children without creating a container node.
public struct Group: ComponentConvertible {
    public let elements: [RenderElement]

    public init(@ComponentBuilder content: () -> [RenderElement]) {
        self.elements = content()
    }

    public func asRenderElements(in context: ComponentContext) -> [RenderElement] {
        elements
    }
}

/// Structural zero-footprint element representing the absence of visual or layout nodes.
public struct Empty: ComponentConvertible {
    public init() {}

    public func asRenderElements(in context: ComponentContext) -> [RenderElement] {
        []
    }
}

/// Collection rendering primitive that assigns stable keys to each element.
///
/// Invariant: Server-driven collections must provide stable unique IDs.
/// Array indices must never serve as persistent identities for dynamic data items.
public struct ForEach<Data: RandomAccessCollection, Content: ComponentConvertible>: ComponentConvertible {
    public let elements: [RenderElement]

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, String>,
        @ComponentBuilder content: (Data.Element) -> Content
    ) {
        self.elements = data.enumerated().flatMap { index, item in
            let key = item[keyPath: id]
            let children = content(item).asRenderElements(in: .default)
            return children.map { child in
                var updated = child
                updated.id = ElementID(
                    typeName: child.id.typeName,
                    key: key,
                    siblingIndex: index
                )
                return updated
            }
        }
    }

    public init<ID: CustomStringConvertible>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ComponentBuilder content: (Data.Element) -> Content
    ) {
        self.elements = data.enumerated().flatMap { index, item in
            let key = item[keyPath: id].description
            let children = content(item).asRenderElements(in: .default)
            return children.map { child in
                var updated = child
                updated.id = ElementID(
                    typeName: child.id.typeName,
                    key: key,
                    siblingIndex: index
                )
                return updated
            }
        }
    }

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ElementKey>,
        @ComponentBuilder content: (Data.Element) -> Content
    ) {
        self.init(data, id: id.appending(path: \.value), content: content)
    }

    public init(
        _ data: Data,
        @ComponentBuilder content: (Data.Element) -> Content
    ) where Data.Element: Identifiable, Data.Element.ID: CustomStringConvertible {
        self.init(data, id: \.id, content: content)
    }

    public func asRenderElements(in context: ComponentContext) -> [RenderElement] {
        elements
    }
}
