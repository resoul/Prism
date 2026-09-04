import Foundation

/// Represents a key character or virtual navigation key for keyboard shortcuts.
public struct KeyEquivalent: Hashable, Sendable, ExpressibleByExtendedGraphemeClusterLiteral {
    public let character: Character

    public init(_ character: Character) {
        self.character = character
    }

    public init(extendedGraphemeClusterLiteral value: Character) {
        self.character = value
    }

    public static let `return`   = KeyEquivalent("\r")
    public static let escape     = KeyEquivalent("\u{1B}")
    public static let tab        = KeyEquivalent("\t")
    public static let space      = KeyEquivalent(" ")
    public static let delete     = KeyEquivalent("\u{7F}")
    public static let upArrow    = KeyEquivalent("\u{F700}")
    public static let downArrow  = KeyEquivalent("\u{F701}")
    public static let leftArrow  = KeyEquivalent("\u{F702}")
    public static let rightArrow = KeyEquivalent("\u{F703}")
}

/// A key and modifier combination that triggers a registered action.
public struct KeyboardShortcut: Hashable, Sendable {
    public let key: KeyEquivalent
    public let modifiers: EventModifiers

    public init(key: KeyEquivalent, modifiers: EventModifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }
}

/// Diagnostic information when multiple elements register the exact same shortcut.
public struct ShortcutConflict: Sendable, Equatable {
    public let shortcut: KeyboardShortcut
    public let existingElementID: ElementID
    public let newElementID: ElementID
}

/// Registry mapping keyboard shortcuts to actions with conflict diagnostics.
@MainActor
public final class KeyboardShortcutRegistry {
    public struct Registration {
        public let elementID: ElementID
        public let action: @MainActor () -> Void
    }

    public private(set) var registrations: [KeyboardShortcut: Registration] = [:]
    public private(set) var conflicts: [ShortcutConflict] = []

    public init() {}

    /// Registers a shortcut for an element, recording a conflict if duplicate registration occurs.
    public func register(
        shortcut: KeyboardShortcut,
        elementID: ElementID,
        action: @escaping @MainActor () -> Void
    ) {
        if let existing = registrations[shortcut], existing.elementID != elementID {
            let conflict = ShortcutConflict(
                shortcut: shortcut,
                existingElementID: existing.elementID,
                newElementID: elementID
            )
            conflicts.append(conflict)
        }
        registrations[shortcut] = Registration(elementID: elementID, action: action)
    }

    /// Unregisters all shortcuts associated with an element ID.
    public func unregister(elementID: ElementID) {
        registrations = registrations.filter { $0.value.elementID != elementID }
    }

    /// Handles a key event by matching registered shortcuts.
    @discardableResult
    public func handleKeyEvent(_ event: Event) -> Bool {
        guard let keyData = event.keyData else { return false }
        guard let firstChar = keyData.charactersIgnoringModifiers.lowercased().first else { return false }

        let queryShortcut = KeyboardShortcut(
            key: KeyEquivalent(firstChar),
            modifiers: keyData.modifiers
        )

        if let registration = registrations[queryShortcut] {
            registration.action()
            event.preventDefault()
            event.stopPropagation()
            return true
        }

        return false
    }

    /// Clears all registrations and recorded conflicts.
    public func reset() {
        registrations.removeAll()
        conflicts.removeAll()
    }
}
