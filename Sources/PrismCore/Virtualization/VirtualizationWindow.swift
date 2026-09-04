import Foundation
import CoreGraphics

/// Calculates visible and overscan item ranges for virtualized lists and grids.
public struct VirtualizationWindow: Sendable, Equatable {
    /// Range of items currently within the viewport bounds.
    public let visibleRange: Range<Int>

    /// Range of items currently mounted including the overscan buffer.
    public let renderedRange: Range<Int>

    /// Total number of items in the dataset.
    public let totalItemCount: Int

    /// Computed total content dimension based on measured and estimated item lengths.
    public let estimatedContentLength: Double

    public init(
        visibleRange: Range<Int>,
        renderedRange: Range<Int>,
        totalItemCount: Int,
        estimatedContentLength: Double
    ) {
        self.visibleRange = visibleRange
        self.renderedRange = renderedRange
        self.totalItemCount = totalItemCount
        self.estimatedContentLength = estimatedContentLength
    }

    /// Computes the virtualization window for a given viewport and item geometry.
    ///
    /// - Parameters:
    ///   - totalCount: Number of items in the collection.
    ///   - viewportLength: Length of the viewport along the scrolling axis.
    ///   - scrollOffset: Current content offset along the scrolling axis.
    ///   - estimatedItemLength: Default length for unmeasured items.
    ///   - measuredLengths: Dictionary of item indices with precisely measured dimensions.
    ///   - overscanFactor: Multiple of viewport length to pre-render ahead and behind (default: 1.0).
    public static func compute(
        totalCount: Int,
        viewportLength: Double,
        scrollOffset: Double,
        estimatedItemLength: Double,
        measuredLengths: [Int: Double] = [:],
        overscanFactor: Double = 1.0
    ) -> VirtualizationWindow {
        guard totalCount > 0, viewportLength > 0, estimatedItemLength > 0 else {
            return VirtualizationWindow(
                visibleRange: 0..<0,
                renderedRange: 0..<0,
                totalItemCount: totalCount,
                estimatedContentLength: 0
            )
        }

        let overscan = viewportLength * overscanFactor
        let visibleMin = max(0, scrollOffset)
        let visibleMax = scrollOffset + viewportLength

        let renderedMin = max(0, visibleMin - overscan)
        let renderedMax = visibleMax + overscan

        var currentOffset: Double = 0
        var firstVisible: Int? = nil
        var lastVisible: Int? = nil
        var firstRendered: Int? = nil
        var lastRendered: Int? = nil

        for i in 0..<totalCount {
            let itemLen = measuredLengths[i] ?? estimatedItemLength
            let itemStart = currentOffset
            let itemEnd = currentOffset + itemLen

            // Rendered window test
            if itemEnd > renderedMin && itemStart < renderedMax {
                if firstRendered == nil { firstRendered = i }
                lastRendered = i
            }

            // Visible window test
            if itemEnd > visibleMin && itemStart < visibleMax {
                if firstVisible == nil { firstVisible = i }
                lastVisible = i
            }

            currentOffset += itemLen
        }

        let rStart = firstRendered ?? 0
        let rEnd = min(totalCount, (lastRendered ?? -1) + 1)

        let vStart = firstVisible ?? 0
        let vEnd = min(totalCount, (lastVisible ?? -1) + 1)

        return VirtualizationWindow(
            visibleRange: vStart..<vEnd,
            renderedRange: rStart..<max(rStart, rEnd),
            totalItemCount: totalCount,
            estimatedContentLength: currentOffset
        )
    }
}
