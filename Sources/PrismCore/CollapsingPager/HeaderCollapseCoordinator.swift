import Foundation
import CoreGraphics

/// Pure Swift, testable state machine that coordinates a shared collapsible header across multiple tabbed pages.
///
/// Ensures the header and tabs behave as a unified physical surface:
/// - Scrolling any active tab down collapses the shared header from `expandedHeight` down to `collapsedHeight`.
/// - Pinned tabs remain docked once the header reaches `collapsedHeight`.
/// - Switching between tabs never causes the header to snap open unexpectedly.
/// - Each tab preserves its own vertical scroll position once the header collapse threshold has been reached.
public final class HeaderCollapseCoordinator: @unchecked Sendable {
    public let expandedHeight: Double
    public let collapsedHeight: Double

    /// Total vertical distance over which the header collapses.
    public var collapseRange: Double {
        max(0.0, expandedHeight - collapsedHeight)
    }

    /// Normalized collapse progression: 0.0 (fully expanded) to 1.0 (fully collapsed).
    public private(set) var collapseProgress: Double = 0.0

    /// Currently active tab page index.
    public private(set) var activePageIndex: Int = 0

    /// Preserved content scroll depth for each page beyond the header collapse threshold.
    public private(set) var pageScrollOffsets: [Int: Double] = [:]

    public init(
        expandedHeight: Double,
        collapsedHeight: Double = 0.0,
        initialPage: Int = 0
    ) {
        self.expandedHeight = max(0.0, expandedHeight)
        self.collapsedHeight = max(0.0, min(collapsedHeight, expandedHeight))
        self.activePageIndex = initialPage
        self.pageScrollOffsets[initialPage] = 0.0
    }

    // MARK: - Computed Dimensions

    /// Current height of the visible portion of the collapsing header.
    public var currentHeaderHeight: Double {
        expandedHeight - (collapseProgress * collapseRange)
    }

    /// Vertical translation offset applied to the header content layer.
    public var headerTranslationY: Double {
        -(collapseProgress * collapseRange)
    }

    /// Whether the header has reached its minimum collapsed height.
    public var isFullyCollapsed: Bool {
        collapseProgress >= 1.0 - 0.001
    }

    /// Whether the header is at its maximum expanded height.
    public var isFullyExpanded: Bool {
        collapseProgress <= 0.001
    }

    // MARK: - Scroll Offset Updates

    /// Applies a vertical scroll offset change from the active page.
    ///
    /// - Parameters:
    ///   - totalScrollOffset: The raw vertical scroll offset of the active page list.
    ///   - page: The index of the reporting page.
    public func updateScrollOffset(_ totalScrollOffset: Double, forPage page: Int) {
        guard page == activePageIndex else {
            // Background / non-active page reports do not mutate active coordinator state
            pageScrollOffsets[page] = max(0.0, totalScrollOffset)
            return
        }

        let offset = max(0.0, totalScrollOffset)

        if collapseRange > 0 {
            if offset <= collapseRange {
                // Within collapse zone: header absorbs the scroll
                collapseProgress = offset / collapseRange
                pageScrollOffsets[page] = 0.0
            } else {
                // Beyond collapse zone: header is fully collapsed, residual offset is page scroll
                collapseProgress = 1.0
                pageScrollOffsets[page] = offset - collapseRange
            }
        } else {
            collapseProgress = 1.0
            pageScrollOffsets[page] = offset
        }
    }

    /// Programmatically updates the page selection.
    ///
    /// - Parameter newPage: The target tab page index.
    /// - Returns: The initial vertical scroll offset that the incoming page should be configured to.
    @discardableResult
    public func selectPage(_ newPage: Int) -> Double {
        activePageIndex = newPage

        // If the header is collapsed, the incoming page should be at least at the collapse boundary
        // so the header does not snap open.
        let existingPageResidual = pageScrollOffsets[newPage] ?? 0.0
        let effectiveHeaderScroll = collapseProgress * collapseRange

        let targetOffset = effectiveHeaderScroll + existingPageResidual
        return targetOffset
    }

    // MARK: - Programmatic Control

    /// Expands the header completely to its full height.
    public func expandHeader() {
        collapseProgress = 0.0
    }

    /// Collapses the header completely to its minimum height.
    public func collapseHeader() {
        collapseProgress = 1.0
    }

    /// Sets explicit collapse progress directly (clamped to 0.0...1.0).
    public func setCollapseProgress(_ progress: Double) {
        collapseProgress = max(0.0, min(1.0, progress))
    }
}
