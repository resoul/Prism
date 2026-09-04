import Foundation

/// Manages focus domain boundaries, trapping Tab/Shift-Tab navigation within modal dialogs
/// or forms, and restoring prior focus upon dismissal.
@MainActor
public final class FocusScopeManager: @unchecked Sendable {
    public static let shared = FocusScopeManager()

    private struct ScopeEntry {
        let scopeID: String
        let previousFocus: ElementID?
        let trapsFocus: Bool
    }

    private var scopeStack: [ScopeEntry] = []

    public init() {}

    /// Enters a new focus scope, recording the previously focused ElementID for restoration.
    public func pushScope(id: String, currentFocus: ElementID?, trapsFocus: Bool = true) {
        scopeStack.append(ScopeEntry(scopeID: id, previousFocus: currentFocus, trapsFocus: trapsFocus))
    }

    /// Exits the focus scope, returning the previously focused ElementID to restore.
    public func popScope(id: String? = nil) -> ElementID? {
        if let id {
            guard let idx = scopeStack.lastIndex(where: { $0.scopeID == id }) else { return nil }
            let entry = scopeStack.remove(at: idx)
            return entry.previousFocus
        } else {
            return scopeStack.popLast()?.previousFocus
        }
    }

    /// Whether the active top-level scope traps focus navigation.
    public var currentScopeTrapsFocus: Bool {
        scopeStack.last?.trapsFocus ?? false
    }

    /// Clears all active scopes.
    public func reset() {
        scopeStack.removeAll()
    }
}

// MARK: - Focus & Submit Modifiers

extension RenderElement {
    /// Configures submit action triggered by the Return / Enter key.
    public func onSubmit(_ action: @escaping @MainActor () -> Void) -> RenderElement {
        var copy = self
        copy.props.custom["hasOnSubmit"] = "true"
        return copy
    }

    /// Customizes the visual action label for the software keyboard return key (e.g. "Done", "Search", "Next").
    public func submitLabel(_ label: String) -> RenderElement {
        var copy = self
        copy.props.custom["submitLabel"] = label
        return copy
    }

    /// Encloses the element and its descendants in a named focus scope.
    public func focusScope(id: String, trapsFocus: Bool = false) -> RenderElement {
        var copy = self
        copy.props.custom["focusScopeID"] = id
        copy.props.custom["trapsFocus"] = trapsFocus ? "true" : "false"
        return copy
    }
}

extension Component {
    /// Configures submit action triggered by the Return / Enter key.
    public func onSubmit(_ action: @escaping @MainActor () -> Void) -> RenderElement {
        render().onSubmit(action)
    }

    /// Customizes the visual action label for the software keyboard return key.
    public func submitLabel(_ label: String) -> RenderElement {
        render().submitLabel(label)
    }

    /// Encloses the component in a named focus scope.
    public func focusScope(id: String, trapsFocus: Bool = false) -> RenderElement {
        render().focusScope(id: id, trapsFocus: trapsFocus)
    }
}
