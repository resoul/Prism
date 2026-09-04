import Foundation

/// Container for element attributes, accessibility descriptors, and debugging metadata.
public struct ElementProps: Equatable, Sendable, CustomStringConvertible {
    public var testID: String?
    public var accessibilityLabel: String?
    public var custom: [String: String]

    public init(
        testID: String? = nil,
        accessibilityLabel: String? = nil,
        custom: [String: String] = [:]
    ) {
        self.testID = testID
        self.accessibilityLabel = accessibilityLabel
        self.custom = custom
    }

    public subscript(dynamicMember member: String) -> String? {
        get { custom[member] }
        set { custom[member] = newValue }
    }

    public var description: String {
        var items: [String] = []
        if let testID { items.append("testID: \"\(testID)\"") }
        if let accessibilityLabel { items.append("accessibilityLabel: \"\(accessibilityLabel)\"") }
        for (k, v) in custom.sorted(by: { $0.key < $1.key }) {
            items.append("\(k): \"\(v)\"")
        }
        return items.joined(separator: ", ")
    }

    public static let empty = ElementProps()
}
