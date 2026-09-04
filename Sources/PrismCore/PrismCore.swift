import Foundation
import Flux
import PrismLogging

/// Core foundation module for Prism UI engine.
///
/// Contains the Virtual Render Tree (VRT), Layout Engine, CALayer/Metal Rendering abstractions,
/// Event/Focus model, Theme token system, and Platform host bridges.
public enum PrismCore {
    public static let version = "0.1.0"
}

/// Fundamental identity for virtual render nodes:
/// identity = `type` + optional `explicit key` + `sibling position`.
public struct ElementID: Hashable, Sendable, CustomStringConvertible {
    public let typeName: String
    public let key: String?
    public let siblingIndex: Int

    public init(typeName: String, key: String? = nil, siblingIndex: Int = 0) {
        self.typeName = typeName
        self.key = key
        self.siblingIndex = siblingIndex
    }

    public var description: String {
        if let key {
            return "\(typeName)[\(key)]@\(siblingIndex)"
        }
        return "\(typeName)@\(siblingIndex)"
    }
}
