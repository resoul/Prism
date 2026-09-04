import Foundation

/// Defines whether the caret aligns with the glyph before or after a line-break boundary.
public enum TextAffinity: String, Hashable, Sendable {
    case upstream
    case downstream
}

/// Represents a selection range or collapsed caret position within a text buffer.
public struct TextSelection: Hashable, Sendable, CustomStringConvertible {
    /// The anchor index where selection originated.
    public var anchor: Int
    /// The active focus index (caret position) that moves during drag or arrow key expansion.
    public var active: Int
    /// Line wrap affinity.
    public var affinity: TextAffinity

    public init(anchor: Int, active: Int, affinity: TextAffinity = .downstream) {
        self.anchor = max(0, anchor)
        self.active = max(0, active)
        self.affinity = affinity
    }

    /// Initializes a collapsed selection at the given caret position.
    public init(caret: Int, affinity: TextAffinity = .downstream) {
        self.init(anchor: caret, active: caret, affinity: affinity)
    }

    /// Initializes a selection covering a range.
    public init(range: Range<Int>, affinity: TextAffinity = .downstream) {
        self.init(anchor: range.lowerBound, active: range.upperBound, affinity: affinity)
    }

    /// Whether the selection is a single collapsed caret point.
    public var isCollapsed: Bool {
        anchor == active
    }

    /// The current caret location (active endpoint of selection).
    public var caretPosition: Int {
        active
    }

    /// The normalized ascending character range.
    public var range: Range<Int> {
        let lower = min(anchor, active)
        let upper = max(anchor, active)
        return lower..<upper
    }

    /// The length of selected characters.
    public var length: Int {
        abs(active - anchor)
    }

    /// The NSRange representation for Cocoa/Foundation bridging.
    public var nsRange: NSRange {
        NSRange(location: range.lowerBound, length: range.count)
    }

    /// Whether selection was dragged/expanded backwards from anchor.
    public var isReversed: Bool {
        active < anchor
    }

    /// Returns a clamped selection within the valid range `0...maxLength`.
    public func clamped(to maxLength: Int) -> TextSelection {
        let clampedAnchor = min(max(0, anchor), maxLength)
        let clampedActive = min(max(0, active), maxLength)
        return TextSelection(anchor: clampedAnchor, active: clampedActive, affinity: affinity)
    }

    public var description: String {
        if isCollapsed {
            return "Caret(\(active))"
        }
        return "Selection(\(anchor) -> \(active))"
    }
}
