import Foundation
import CoreGraphics

/// Scrolling orientation axis.
public enum ScrollAxis: String, Sendable, Equatable, Codable {
    case vertical
    case horizontal
    case both
}

/// Alignment anchor when programmatically scrolling to a target.
public enum ScrollAnchor: String, Sendable, Equatable, Codable {
    case top
    case center
    case bottom
    case leading
    case trailing
}

/// Current metrics and position of a scrollable viewport.
public struct ScrollPosition: Sendable, Equatable {
    /// Current content offset in points relative to viewport origin.
    public var offset: CGPoint

    /// Total size of the scrollable content.
    public var contentSize: CGSize

    /// Visible size of the scroll viewport.
    public var viewportSize: CGSize

    public init(
        offset: CGPoint = .zero,
        contentSize: CGSize = .zero,
        viewportSize: CGSize = .zero
    ) {
        self.offset = offset
        self.contentSize = contentSize
        self.viewportSize = viewportSize
    }

    /// Maximum valid scroll offset without overscroll/rubber-banding.
    public var maxOffset: CGPoint {
        CGPoint(
            x: max(0, contentSize.width - viewportSize.width),
            y: max(0, contentSize.height - viewportSize.height)
        )
    }

    /// Normalized progress along the vertical axis [0.0 ... 1.0].
    public var verticalProgress: Double {
        let limitY = maxOffset.y
        guard limitY > 0 else { return 0 }
        return Double(min(limitY, max(0, offset.y)) / limitY)
    }

    /// Normalized progress along the horizontal axis [0.0 ... 1.0].
    public var horizontalProgress: Double {
        let limitX = maxOffset.x
        guard limitX > 0 else { return 0 }
        return Double(min(limitX, max(0, offset.x)) / limitX)
    }
}

/// Serializable snapshot for restoring scroll state across navigation.
public struct ScrollStateSnapshot: Sendable, Equatable, Codable {
    public let offsetX: Double
    public let offsetY: Double

    public init(offset: CGPoint) {
        self.offsetX = Double(offset.x)
        self.offsetY = Double(offset.y)
    }

    public var offset: CGPoint {
        CGPoint(x: offsetX, y: offsetY)
    }
}

/// Stable target within a scroll area.
public struct ScrollTarget: Sendable, Equatable {
    public let id: String
    public let frame: CGRect

    public init(id: String, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

/// State machine for pull-to-refresh interactions.
public enum PullToRefreshState: Sendable, Equatable {
    case idle
    case pulling(progress: Double)
    case refreshing
    case completed
}
