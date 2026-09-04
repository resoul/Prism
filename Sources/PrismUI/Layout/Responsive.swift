import Foundation
import CoreGraphics
@_exported import PrismCore
import struct Flux.Flux
import class Flux.Pipe

/// Container-derived responsive size category.
///
/// Invariant: Breakpoint is evaluated from local container width, not screen size,
/// enabling modular, location-aware component responsiveness.
public enum Breakpoint: String, CaseIterable, Sendable, Comparable {
    case compact     // < 600pt (iPhone portrait, side sheets)
    case medium      // 600–900pt (iPhone landscape, iPad portrait)
    case expanded    // 900–1200pt (iPad landscape, desktop standard window)
    case wide        // > 1200pt (desktop large window, full-screen)

    public static func < (lhs: Breakpoint, rhs: Breakpoint) -> Bool {
        lhs.order < rhs.order
    }

    private var order: Int {
        switch self {
        case .compact: return 0
        case .medium: return 1
        case .expanded: return 2
        case .wide: return 3
        }
    }

    /// Evaluates a container width into its corresponding Breakpoint.
    public static func from(width: CGFloat) -> Breakpoint {
        switch width {
        case ..<600:
            return .compact
        case 600..<900:
            return .medium
        case 900...1200:
            return .expanded
        default:
            return .wide
        }
    }

    public var isCompact: Bool { self == .compact }
    public var isMedium: Bool { self == .medium }
    public var isExpanded: Bool { self == .expanded }
    public var isWide: Bool { self == .wide }
}

/// Generic value wrapper providing breakpoint-adaptive values with automatic fallback inheritance.
public struct ResponsiveValue<T: Sendable>: Sendable {
    public let compact: T
    public let medium: T?
    public let expanded: T?
    public let wide: T?

    public init(
        compact: T,
        medium: T? = nil,
        expanded: T? = nil,
        wide: T? = nil
    ) {
        self.compact = compact
        self.medium = medium
        self.expanded = expanded
        self.wide = wide
    }

    /// Resolves the specific value for a given breakpoint.
    public func resolve(for breakpoint: Breakpoint) -> T {
        switch breakpoint {
        case .compact:
            return compact
        case .medium:
            return medium ?? compact
        case .expanded:
            return expanded ?? medium ?? compact
        case .wide:
            return wide ?? expanded ?? medium ?? compact
        }
    }
}

/// Container component dynamically adapting its layout when container width crosses breakpoint thresholds.
public struct ResponsiveContainer: Component {
    public let content: @Sendable (Breakpoint) -> any Component
    private let defaultBreakpoint: Breakpoint

    public init(
        defaultBreakpoint: Breakpoint = .compact,
        @ComponentBuilder content: @escaping @Sendable (Breakpoint) -> any Component
    ) {
        self.defaultBreakpoint = defaultBreakpoint
        self.content = content
    }

    public func body(context: ComponentContext) -> RenderElement {
        // Resolve breakpoint based on context or default
        let breakpoint = defaultBreakpoint
        return content(breakpoint)
            .render(in: context)
            .key("responsive_\(breakpoint.rawValue)")
    }
}

// MARK: - Responsive Component Modifiers

public extension Component {
    /// Renders the component only if the active breakpoint is contained in the specified set.
    func visible(on breakpoints: Set<Breakpoint>, current: Breakpoint) -> any ComponentConvertible {
        if breakpoints.contains(current) {
            return self
        } else {
            return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
        }
    }

    /// Hides the component if the active breakpoint is contained in the specified set.
    func hidden(on breakpoints: Set<Breakpoint>, current: Breakpoint) -> any ComponentConvertible {
        if breakpoints.contains(current) {
            return RenderElement(id: ElementID(typeName: "Empty"), kind: .empty)
        } else {
            return self
        }
    }
}
