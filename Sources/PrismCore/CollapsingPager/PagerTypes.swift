import Foundation
import CoreGraphics

/// Represents the transition phase of a horizontal page pager.
public enum PagerTransitionState: Sendable, Equatable {
    case idle
    case dragging(translation: CGFloat)
    case animating(fromIndex: Int, toIndex: Int, progress: Double)
}

/// Mount policy controlling which pages are instantiated in the render tree.
public enum NeighbourMountPolicy: Sendable, Equatable {
    /// Mounts only the currently visible page and its immediate left/right neighbours.
    /// Distant pages are unmounted to release CALayers and pause background tasks.
    case immediateNeighbours

    /// Computes the active set of page indices that should be mounted for a given selection and total count.
    public func activeIndices(selected: Int, total: Int) -> Set<Int> {
        guard total > 0 else { return [] }
        var result = Set<Int>()
        result.insert(selected)
        if selected - 1 >= 0 {
            result.insert(selected - 1)
        }
        if selected + 1 < total {
            result.insert(selected + 1)
        }
        return result
    }
}

/// Tab identifier contract for tab pagers.
public protocol TabItem: Sendable, Hashable, Identifiable {
    var title: String { get }
}

/// Generic tab page declaration wrapping page contents.
public struct TabPage<Tab: TabItem>: Sendable {
    public let tab: Tab
    public let contentProvider: @Sendable () -> [RenderElement]

    public init(
        _ tab: Tab,
        content: @escaping @Sendable () -> [RenderElement]
    ) {
        self.tab = tab
        self.contentProvider = content
    }
}
