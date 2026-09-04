import Foundation

/// Pure, immutable value representing a node in the Virtual Render Tree.
///
/// Invariant: Must never contain references to CALayer, UIView, NSView, or host platform objects.
public struct RenderElement: Equatable, Sendable, CustomStringConvertible {
    public var id: ElementID
    public var kind: ElementKind
    public var props: ElementProps
    public var modifiers: [ElementModifier]
    public var children: [RenderElement]

    public init(
        id: ElementID,
        kind: ElementKind,
        props: ElementProps = ElementProps(),
        modifiers: [ElementModifier] = [],
        children: [RenderElement] = []
    ) {
        self.id = id
        self.kind = kind
        self.props = props
        self.modifiers = modifiers
        self.children = children
    }

    public var resolvedStyle: ResolvedStyle {
        ResolvedStyle.resolve(from: modifiers)
    }

    public var description: String {
        dumpTree()
    }

    /// Normalizes the element tree:
    /// - Inlines structural `Group` children
    /// - Prunes `Empty` children
    /// - Reassigns sibling indices deterministically
    public func normalized() -> RenderElement {
        var normalizedChildren: [RenderElement] = []

        func collect(_ elements: [RenderElement]) {
            for element in elements {
                let normalizedElement = element.normalized()
                switch normalizedElement.kind {
                case .empty:
                    continue
                case .group:
                    collect(normalizedElement.children)
                default:
                    normalizedChildren.append(normalizedElement)
                }
            }
        }

        collect(children)

        let reindexedChildren = normalizedChildren.enumerated().map { index, child in
            var updated = child
            updated.id = child.id.withSiblingIndex(index)
            return updated
        }

        var copy = self
        copy.children = reindexedChildren
        return copy
    }

    /// Generates a human-readable and testable visual dump of the element tree.
    public func dumpTree(indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var line = "\(prefix)\(kind)"

        if let key = id.key {
            line += " [key: \"\(key)\"]"
        }

        if id.siblingIndex > 0 {
            line += " [sibling: \(id.siblingIndex)]"
        }

        if let testID = props.testID {
            line += " [testID: \"\(testID)\"]"
        }

        if !modifiers.isEmpty {
            let modifierDescriptions = modifiers.map { $0.description }.joined(separator: ", ")
            line += " {\(modifierDescriptions)}"
        }

        if children.isEmpty {
            return line
        }

        let childLines = children.map { $0.dumpTree(indent: indent + 1) }.joined(separator: "\n")
        return "\(line)\n\(childLines)"
    }
}

// MARK: - Modifiers on RenderElement

extension RenderElement {
    public func width(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.width(value))
        return copy
    }

    public func height(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.height(value))
        return copy
    }

    public func frame(width: Double? = nil, height: Double? = nil) -> RenderElement {
        var copy = self
        if let width { copy.modifiers.append(.width(width)) }
        if let height { copy.modifiers.append(.height(height)) }
        return copy
    }

    public func minWidth(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.minWidth(value))
        return copy
    }

    public func maxWidth(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.maxWidth(value))
        return copy
    }

    public func minHeight(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.minHeight(value))
        return copy
    }

    public func maxHeight(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.maxHeight(value))
        return copy
    }

    public func padding(_ insets: DirectionalEdgeInsets) -> RenderElement {
        var copy = self
        copy.modifiers.append(.padding(insets))
        return copy
    }

    public func padding(_ all: Double) -> RenderElement {
        padding(DirectionalEdgeInsets(all: all))
    }

    public func padding(
        top: Double = 0,
        leading: Double = 0,
        bottom: Double = 0,
        trailing: Double = 0
    ) -> RenderElement {
        padding(DirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
    }

    public func margin(_ insets: DirectionalEdgeInsets) -> RenderElement {
        var copy = self
        copy.modifiers.append(.margin(insets))
        return copy
    }

    public func margin(_ all: Double) -> RenderElement {
        margin(DirectionalEdgeInsets(all: all))
    }

    public func margin(
        top: Double = 0,
        leading: Double = 0,
        bottom: Double = 0,
        trailing: Double = 0
    ) -> RenderElement {
        margin(DirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
    }

    public func background(_ color: Color) -> RenderElement {
        var copy = self
        copy.modifiers.append(.background(color))
        return copy
    }

    public func opacity(_ value: Double) -> RenderElement {
        var copy = self
        copy.modifiers.append(.opacity(value))
        return copy
    }

    public func zIndex(_ value: Int) -> RenderElement {
        var copy = self
        copy.modifiers.append(.zIndex(value))
        return copy
    }

    public func key(_ key: String) -> RenderElement {
        var copy = self
        copy.id = copy.id.withKey(key)
        copy.modifiers.append(.explicitKey(key))
        return copy
    }

    public func testID(_ id: String) -> RenderElement {
        var copy = self
        copy.props.testID = id
        copy.modifiers.append(.testID(id))
        return copy
    }

    public func accessibilityLabel(_ label: String) -> RenderElement {
        var copy = self
        copy.props.accessibilityLabel = label
        return copy
    }
}
