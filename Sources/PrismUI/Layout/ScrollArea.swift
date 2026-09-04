import Foundation
import CoreGraphics
import PrismCore

/// Proxy interface for programmatic scrolling within a `ScrollArea`.
public struct ScrollProxy: Sendable {
    private let _scrollToOffset: @MainActor @Sendable (CGPoint) -> Void
    private let _scrollToTarget: @MainActor @Sendable (String, ScrollAnchor) -> Void

    public init(
        scrollToOffset: @escaping @MainActor @Sendable (CGPoint) -> Void,
        scrollToTarget: @escaping @MainActor @Sendable (String, ScrollAnchor) -> Void
    ) {
        self._scrollToOffset = scrollToOffset
        self._scrollToTarget = scrollToTarget
    }

    @MainActor
    public func scrollTo(_ offset: CGPoint) {
        _scrollToOffset(offset)
    }

    @MainActor
    public func scrollTo(_ id: String, anchor: ScrollAnchor = .top) {
        _scrollToTarget(id, anchor)
    }
}

/// Declarative scroll container providing viewport clipping, bounce physics,
/// momentum scrolling, and programmatic scroll coordination.
public struct ScrollArea: Component {
    private let axis: ScrollAxis
    private let bounces: Bool
    private let onScroll: (@Sendable (ScrollPosition) -> Void)?
    private let refreshAction: (@Sendable () async -> Void)?
    private let content: [RenderElement]

    public init(
        _ axis: ScrollAxis = .vertical,
        bounces: Bool = true,
        onScroll: (@Sendable (ScrollPosition) -> Void)? = nil,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.axis = axis
        self.bounces = bounces
        self.onScroll = onScroll
        self.refreshAction = nil
        self.content = content()
    }

    private init(
        axis: ScrollAxis,
        bounces: Bool,
        onScroll: (@Sendable (ScrollPosition) -> Void)?,
        refreshAction: (@Sendable () async -> Void)?,
        content: [RenderElement]
    ) {
        self.axis = axis
        self.bounces = bounces
        self.onScroll = onScroll
        self.refreshAction = refreshAction
        self.content = content
    }

    /// Attaches an asynchronous pull-to-refresh action.
    public func refreshable(action: @escaping @Sendable () async -> Void) -> ScrollArea {
        ScrollArea(
            axis: axis,
            bounces: bounces,
            onScroll: onScroll,
            refreshAction: action,
            content: content
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        var props = ElementProps()
        props.custom["scrollAxis"] = axis.rawValue
        props.custom["bounces"] = bounces ? "true" : "false"
        if refreshAction != nil {
            props.custom["isRefreshable"] = "true"
        }

        return RenderElement(
            id: ElementID(typeName: "ScrollArea"),
            kind: .scrollArea(axis: axis),
            props: props,
            modifiers: [],
            children: content
        )
    }
}

// MARK: - Modifiers

extension RenderElement {
    /// Marks this element as a stable scroll destination that can be navigated to via `ScrollProxy.scrollTo(id:)`.
    public func scrollTarget(_ id: String) -> RenderElement {
        var copy = self
        copy.props.custom["scrollTargetID"] = id
        return copy
    }

    /// Pins this header section to the top of its enclosing scroll viewport during scroll.
    public func pinnedHeader(_ isPinned: Bool = true) -> RenderElement {
        var copy = self
        copy.props.custom["isPinnedHeader"] = isPinned ? "true" : "false"
        return copy
    }
}

extension Component {
    /// Marks this component as a stable scroll destination.
    public func scrollTarget(_ id: String) -> RenderElement {
        render().scrollTarget(id)
    }

    /// Pins this header component to the top of its enclosing scroll viewport.
    public func pinnedHeader(_ isPinned: Bool = true) -> RenderElement {
        render().pinnedHeader(isPinned)
    }
}
