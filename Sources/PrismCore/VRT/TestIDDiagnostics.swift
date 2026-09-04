import Foundation

/// Represents a detected duplicate test identifier conflict within the element tree.
public struct TestIDConflict: Equatable, Sendable, CustomStringConvertible {
    public let testID: String
    public let elementIDs: [ElementID]

    public init(testID: String, elementIDs: [ElementID]) {
        self.testID = testID
        self.elementIDs = elementIDs
    }

    public var description: String {
        "Duplicate testID '\(testID)' detected across \(elementIDs.count) elements: \(elementIDs.map(\.description).joined(separator: ", "))"
    }
}

/// Development diagnostic validator for identifying duplicate or conflicting testIDs.
public enum TestIDValidator {

    /// Inspects an immutable `RenderElement` tree and returns all duplicate testID conflicts.
    public static func findConflicts(in root: RenderElement) -> [TestIDConflict] {
        var map: [String: [ElementID]] = [:]

        func collect(element: RenderElement) {
            if let testID = element.props.testID {
                map[testID, default: []].append(element.id)
            }
            for child in element.children {
                collect(element: child)
            }
        }

        collect(element: root)

        return map.compactMap { key, ids in
            ids.count > 1 ? TestIDConflict(testID: key, elementIDs: ids) : nil
        }.sorted { $0.testID < $1.testID }
    }

    /// Inspects a live `MountedNode` tree and returns all duplicate testID conflicts.
    @MainActor
    public static func findConflicts(in root: MountedNode) -> [TestIDConflict] {
        var map: [String: [ElementID]] = [:]

        func collect(node: MountedNode) {
            if let testID = node.element.props.testID {
                map[testID, default: []].append(node.id)
            }
            for child in node.children {
                collect(node: child)
            }
        }

        collect(node: root)

        return map.compactMap { key, ids in
            ids.count > 1 ? TestIDConflict(testID: key, elementIDs: ids) : nil
        }.sorted { $0.testID < $1.testID }
    }
}
