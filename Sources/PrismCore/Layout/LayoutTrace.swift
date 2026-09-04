import Foundation

/// Formats a comprehensive visual layout tree trace showing frames, constraints,
/// and styling parameters for diagnostics and integration test failure analysis.
public enum LayoutTrace {

    /// Generates a formatted layout trace string for a node hierarchy.
    public static func dump(_ node: LayoutNode, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var line = "\(prefix)Node(\(node.id))"

        if let frame = node.layoutFrame {
            line += " frame: (\(frame.origin.x), \(frame.origin.y), \(frame.width), \(frame.height))"
        } else {
            line += " [unpositioned]"
        }

        if let desired = node.measuredSize {
            line += " desired: (\(desired.width), \(desired.height))"
        }

        if let constraint = node.debugData.measureConstraint {
            line += " constraint: [\(constraint.width), \(constraint.height)]"
        }

        var styleAttributes: [String] = []
        if node.style.positionType != .flow {
            styleAttributes.append("pos: \(node.style.positionType)")
        }
        if node.style.zIndex != 0 {
            styleAttributes.append("z: \(node.style.zIndex)")
        }
        if node.style.flexGrow > 0 {
            styleAttributes.append("grow: \(node.style.flexGrow)")
        }
        if node.style.flexShrink > 0 {
            styleAttributes.append("shrink: \(node.style.flexShrink)")
        }
        if !node.children.isEmpty {
            styleAttributes.append("dir: \(node.style.direction)")
            if node.style.gap > 0 {
                styleAttributes.append("gap: \(node.style.gap)")
            }
        }

        if !styleAttributes.isEmpty {
            line += " {\(styleAttributes.joined(separator: ", "))}"
        }

        if node.children.isEmpty {
            return line
        }

        let childLines = node.children.map { dump($0, indent: indent + 1) }.joined(separator: "\n")
        return "\(line)\n\(childLines)"
    }
}

extension LayoutNode {
    /// Produces a human-readable visual trace of the node and its descendants.
    public func dumpTrace() -> String {
        LayoutTrace.dump(self)
    }
}
