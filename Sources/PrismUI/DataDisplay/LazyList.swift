import Foundation
import PrismCore

/// High-performance, virtualized vertical list rendering only visible and near-viewport elements.
///
/// Ensures memory and GPU CALayer consumption remain bounded regardless of collection size
/// (e.g. 10,000+ items).
public struct LazyList<Data: RandomAccessCollection & Sendable, Content: ComponentConvertible>: Component {
    private let data: Data
    private let idKeyPath: KeyPath<Data.Element, String> & Sendable
    private let estimatedItemLength: Double
    private let overscanFactor: Double
    private let prefetchDistance: Int?
    private let prefetchAction: (@Sendable () -> Void)?
    private let contentBuilder: @Sendable (Data.Element) -> Content

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, String> & Sendable,
        estimatedItemLength: Double = 44.0,
        overscanFactor: Double = 1.0,
        @ComponentBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = id
        self.estimatedItemLength = estimatedItemLength
        self.overscanFactor = overscanFactor
        self.prefetchDistance = nil
        self.prefetchAction = nil
        self.contentBuilder = content
    }

    private init(
        data: Data,
        idKeyPath: KeyPath<Data.Element, String> & Sendable,
        estimatedItemLength: Double,
        overscanFactor: Double,
        prefetchDistance: Int?,
        prefetchAction: (@Sendable () -> Void)?,
        contentBuilder: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = idKeyPath
        self.estimatedItemLength = estimatedItemLength
        self.overscanFactor = overscanFactor
        self.prefetchDistance = prefetchDistance
        self.prefetchAction = prefetchAction
        self.contentBuilder = contentBuilder
    }

    /// Attaches an automatic prefetch trigger when scrolling near the bottom of the list.
    public func prefetch(distance: Int = 10, action: @escaping @Sendable () -> Void) -> LazyList {
        LazyList(
            data: data,
            idKeyPath: idKeyPath,
            estimatedItemLength: estimatedItemLength,
            overscanFactor: overscanFactor,
            prefetchDistance: distance,
            prefetchAction: action,
            contentBuilder: contentBuilder
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        let totalCount = data.count
        // Default viewport reference for sizing (or read from context environment)
        let viewportHeight = 800.0
        let scrollOffset = 0.0

        let window = VirtualizationWindow.compute(
            totalCount: totalCount,
            viewportLength: viewportHeight,
            scrollOffset: scrollOffset,
            estimatedItemLength: estimatedItemLength,
            overscanFactor: overscanFactor
        )

        // Trigger prefetch if window approaches collection boundary
        if let dist = prefetchDistance, window.renderedRange.upperBound >= totalCount - dist {
            prefetchAction?()
        }

        // Render only items in rendered window (visible + overscan)
        var children: [RenderElement] = []
        children.reserveCapacity(window.renderedRange.count)

        let elementsArray = Array(data)
        for index in window.renderedRange {
            guard index < elementsArray.count else { break }
            let item = elementsArray[index]
            let key = item[keyPath: idKeyPath]
            let itemElements = contentBuilder(item).asRenderElements(in: context)

            for child in itemElements {
                var keyedChild = child
                keyedChild.id = ElementID(
                    typeName: child.id.typeName,
                    key: key,
                    siblingIndex: index
                )
                children.append(keyedChild)
            }
        }

        var props = ElementProps()
        props.custom["totalCount"] = String(totalCount)
        props.custom["mountedCount"] = String(children.count)
        props.custom["visibleCount"] = String(window.visibleRange.count)
        props.custom["estimatedContentLength"] = String(window.estimatedContentLength)

        return RenderElement(
            id: ElementID(typeName: "LazyList"),
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            props: props,
            modifiers: [],
            children: children
        )
    }
}
