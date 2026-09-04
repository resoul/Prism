import Foundation

/// Invalidation lifecycle state of a layout node.
public enum LayoutInvalidationState: Equatable, Sendable, CustomStringConvertible {
    /// Node is completely up-to-date; measure and layout passes are cached.
    case clean

    /// Position or parent frame changed; children need re-layout, but measure cache remains valid.
    case layoutInvalidated

    /// Content, style, or intrinsic sizing changed; both measure and layout must be recomputed.
    case measureInvalidated

    public var description: String {
        switch self {
        case .clean: return "clean"
        case .layoutInvalidated: return "layoutInvalidated"
        case .measureInvalidated: return "measureInvalidated"
        }
    }
}

/// Diagnostic metadata captured during layout passes for inspection in development builds and tests.
public struct LayoutDebugData: Equatable, Sendable, CustomStringConvertible {
    public var measureConstraint: SizeConstraint?
    public var desiredSize: MeasuredSize?
    public var assignedFrame: LayoutFrame?

    public init(
        measureConstraint: SizeConstraint? = nil,
        desiredSize: MeasuredSize? = nil,
        assignedFrame: LayoutFrame? = nil
    ) {
        self.measureConstraint = measureConstraint
        self.desiredSize = desiredSize
        self.assignedFrame = assignedFrame
    }

    public var description: String {
        "DebugData(constraint: \(measureConstraint.map { "\($0)" } ?? "nil"), desired: \(desiredSize.map { "\($0)" } ?? "nil"), frame: \(assignedFrame.map { "\($0)" } ?? "nil"))"
    }
}

/// Fundamental node in the layout tree responsible for the two-pass layout computation.
///
/// Invariant: Must never contain references to CALayer, UIView, NSView, or host platform views.
public final class LayoutNode: @unchecked Sendable {
    public let id: ElementID
    public var style: LayoutStyle {
        didSet {
            if oldValue != style {
                invalidateMeasure()
            }
        }
    }
    public var children: [LayoutNode] {
        didSet {
            invalidateMeasure()
        }
    }
    public var measurePolicy: MeasurePolicy? {
        didSet {
            invalidateMeasure()
        }
    }

    public private(set) var measuredSize: MeasuredSize?
    public private(set) var layoutFrame: LayoutFrame?
    public private(set) var invalidationState: LayoutInvalidationState = .measureInvalidated
    public var debugData: LayoutDebugData = LayoutDebugData()

    public init(
        id: ElementID,
        style: LayoutStyle = .default,
        children: [LayoutNode] = [],
        measurePolicy: MeasurePolicy? = nil
    ) {
        self.id = id
        self.style = style
        self.children = children
        self.measurePolicy = measurePolicy
    }

    // MARK: - Pass 1: Measure

    /// Computes and caches the desired size of this node given parent constraints.
    @discardableResult
    public func measure(constraint: SizeConstraint) -> MeasuredSize {
        // Check cache if clean
        if invalidationState == .clean, let cached = measuredSize, debugData.measureConstraint == constraint {
            return cached
        }

        let computedSize: MeasuredSize

        if let policy = measurePolicy {
            computedSize = policy.measure(style: style, constraint: constraint)
        } else if children.isEmpty {
            let paddingH = style.padding.leading + style.padding.trailing
            let paddingV = style.padding.top + style.padding.bottom
            computedSize = ConstraintResolver.resolveSize(
                style: style,
                constraint: constraint,
                intrinsic: MeasuredSize(width: paddingH, height: paddingV)
            )
        } else {
            computedSize = FlexSolver.measureContainer(node: self, constraint: constraint)
        }

        self.measuredSize = computedSize
        self.debugData.measureConstraint = constraint
        self.debugData.desiredSize = computedSize

        if invalidationState == .measureInvalidated {
            invalidationState = .layoutInvalidated
        }

        return computedSize
    }

    // MARK: - Pass 2: Layout

    /// Assigns the final layout frame, positions children, and updates invalidation state to clean.
    public func layout(frame: LayoutFrame, roundingPolicy: PixelRoundingPolicy = PixelRoundingPolicy()) {
        let roundedFrame = roundingPolicy.roundFrame(frame)
        self.layoutFrame = roundedFrame
        self.debugData.assignedFrame = roundedFrame
        self.invalidationState = .clean

        if !children.isEmpty {
            FlexSolver.layoutContainer(node: self, frame: roundedFrame, roundingPolicy: roundingPolicy)
        }
    }

    // MARK: - Invalidation Contract

    /// Content or style changed: invalidate both measure and layout.
    public func invalidateMeasure() {
        invalidationState = .measureInvalidated
        measuredSize = nil
        layoutFrame = nil
    }

    /// Frame or position changed: invalidate layout while retaining valid measure cache.
    public func invalidateLayout() {
        if invalidationState == .clean {
            invalidationState = .layoutInvalidated
            layoutFrame = nil
        }
    }
}
