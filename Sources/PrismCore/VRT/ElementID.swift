import Foundation

/// Fundamental identity for virtual render nodes:
/// identity = `type` + optional `explicit key` + `sibling position`.
public struct ElementID: Hashable, Sendable, CustomStringConvertible, Codable {
    public let typeName: String
    public let key: String?
    public let siblingIndex: Int

    public init(typeName: String, key: String? = nil, siblingIndex: Int = 0) {
        self.typeName = typeName
        self.key = key
        self.siblingIndex = siblingIndex
    }

    public func withSiblingIndex(_ index: Int) -> ElementID {
        ElementID(typeName: typeName, key: key, siblingIndex: index)
    }

    public func withKey(_ newKey: String?) -> ElementID {
        ElementID(typeName: typeName, key: newKey, siblingIndex: siblingIndex)
    }

    public var description: String {
        if let key {
            return "\(typeName)[\(key)]@\(siblingIndex)"
        }
        return "\(typeName)@\(siblingIndex)"
    }
}
