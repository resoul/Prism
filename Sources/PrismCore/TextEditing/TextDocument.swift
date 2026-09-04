import Foundation

/// Core in-memory editable text buffer managing string mutations, grapheme clusters,
/// UTF-16 conversions, selection ranges, marked composing text (IME), and undo/redo transactions.
@MainActor
public final class TextDocument: @unchecked Sendable {
    /// The full text content.
    public private(set) var text: String {
        didSet {
            if text != oldValue {
                onChange?(text)
            }
        }
    }

    /// The active selection or collapsed caret position.
    public var selection: TextSelection {
        didSet {
            let clamped = selection.clamped(to: text.count)
            if selection != clamped {
                selection = clamped
            }
            if selection != oldValue {
                onSelectionChange?(selection)
            }
        }
    }

    /// The marked range used by IME composition.
    public private(set) var markedRange: Range<Int>? = nil

    /// The selected range within the marked text.
    public private(set) var selectedMarkedRange: Range<Int>? = nil

    /// Maximum character limit if configured.
    public var maxLength: Int? = nil

    /// Associated Foundation `UndoManager` for native undo/redo integration.
    public weak var undoManager: UndoManager? = nil

    /// Closure invoked whenever text content changes.
    public var onChange: (@MainActor (String) -> Void)? = nil

    /// Closure invoked whenever the selection/caret changes.
    public var onSelectionChange: (@MainActor (TextSelection) -> Void)? = nil

    /// Closure invoked when the return/submit action is triggered.
    public var onSubmit: (@MainActor () -> Void)? = nil

    public init(
        text: String = "",
        selection: TextSelection? = nil,
        maxLength: Int? = nil,
        undoManager: UndoManager? = nil
    ) {
        self.text = text
        self.selection = selection ?? TextSelection(caret: text.count)
        self.maxLength = maxLength
        self.undoManager = undoManager
    }

    // MARK: - Text Replacement & Mutations

    /// Replaces the currently selected text or inserts string at caret.
    public func insert(_ string: String) {
        if let max = maxLength, (text.count - selection.length + string.count) > max {
            let available = max - (text.count - selection.length)
            if available <= 0 { return }
            let truncated = String(string.prefix(available))
            replace(range: selection.range, with: truncated)
            return
        }
        replace(range: selection.range, with: string)
    }

    /// Deletes text preceding the caret or the current selection.
    public func deleteBackward() {
        if !selection.isCollapsed {
            replace(range: selection.range, with: "")
            return
        }

        let pos = selection.caretPosition
        guard pos > 0 else { return }

        let index = stringIndex(for: pos)
        let prevIndex = text.index(before: index)
        let prevPos = text.distance(from: text.startIndex, to: prevIndex)

        replace(range: prevPos..<pos, with: "")
    }

    /// Deletes text succeeding the caret or the current selection.
    public func deleteForward() {
        if !selection.isCollapsed {
            replace(range: selection.range, with: "")
            return
        }

        let pos = selection.caretPosition
        guard pos < text.count else { return }

        let index = stringIndex(for: pos)
        let nextIndex = text.index(after: index)
        let nextPos = text.distance(from: text.startIndex, to: nextIndex)

        replace(range: pos..<nextPos, with: "")
    }

    /// Deletes the word preceding the caret.
    public func deleteWordBackward() {
        if !selection.isCollapsed {
            replace(range: selection.range, with: "")
            return
        }

        let pos = selection.caretPosition
        guard pos > 0 else { return }

        let wordStart = previousWordBoundary(from: pos)
        replace(range: wordStart..<pos, with: "")
    }

    /// Deletes from the caret to the beginning of the line.
    public func deleteToBeginningOfLine() {
        if !selection.isCollapsed {
            replace(range: selection.range, with: "")
            return
        }

        let pos = selection.caretPosition
        guard pos > 0 else { return }

        let lineStart = lineStartBoundary(from: pos)
        replace(range: lineStart..<pos, with: "")
    }

    /// Replaces an arbitrary character range with new text, recording undo actions.
    public func replace(range: Range<Int>, with replacement: String) {
        let clampedRange = min(max(0, range.lowerBound), text.count)..<min(max(0, range.upperBound), text.count)
        let oldSub = substring(for: clampedRange)

        // Register undo
        if let undo = undoManager {
            let undoRange = clampedRange.lowerBound..<(clampedRange.lowerBound + replacement.count)
            let oldSelection = self.selection
            undo.registerUndo(withTarget: self) { [oldSub, undoRange, oldSelection] doc in
                doc.replace(range: undoRange, with: oldSub)
                doc.selection = oldSelection
            }
        }

        let startIdx = stringIndex(for: clampedRange.lowerBound)
        let endIdx = stringIndex(for: clampedRange.upperBound)
        text.replaceSubrange(startIdx..<endIdx, with: replacement)

        let newCaret = clampedRange.lowerBound + replacement.count
        selection = TextSelection(caret: newCaret)
        unmarkText()
    }

    /// Updates the entire document text externally, preserving or clamping the caret.
    public func setText(_ newText: String) {
        guard newText != text else { return }
        text = newText
        selection = selection.clamped(to: text.count)
        unmarkText()
    }

    // MARK: - Marked / Composing Text (IME)

    /// Sets the marked (composing) text during multi-stage IME input.
    public func setMarkedText(_ string: String, selectedRange: Range<Int>? = nil) {
        let targetRange = markedRange ?? selection.range
        replace(range: targetRange, with: string)

        let markStart = targetRange.lowerBound
        let markEnd = markStart + string.count
        self.markedRange = markStart..<markEnd

        if let sel = selectedRange {
            let absStart = markStart + sel.lowerBound
            let absEnd = markStart + sel.upperBound
            self.selectedMarkedRange = absStart..<absEnd
            self.selection = TextSelection(anchor: absStart, active: absEnd)
        } else {
            self.selectedMarkedRange = nil
            self.selection = TextSelection(caret: markEnd)
        }
    }

    /// Commits active composing text into permanent document content.
    public func unmarkText() {
        markedRange = nil
        selectedMarkedRange = nil
    }

    /// Whether there is active composing text in the document.
    public var hasMarkedText: Bool {
        markedRange != nil
    }

    // MARK: - Caret & Selection Navigation

    /// Selects the entire text in the document.
    public func selectAll() {
        selection = TextSelection(anchor: 0, active: text.count)
    }

    /// Moves the caret to the specified position, optionally expanding selection.
    public func moveCaret(to position: Int, extendSelection: Bool = false) {
        let clamped = min(max(0, position), text.count)
        if extendSelection {
            selection = TextSelection(anchor: selection.anchor, active: clamped)
        } else {
            selection = TextSelection(caret: clamped)
        }
    }

    /// Moves caret backward by one grapheme cluster.
    public func moveLeft(extendSelection: Bool = false) {
        if !extendSelection && !selection.isCollapsed {
            moveCaret(to: selection.range.lowerBound)
            return
        }
        let pos = selection.caretPosition
        guard pos > 0 else { return }
        let prev = text.distance(from: text.startIndex, to: text.index(before: stringIndex(for: pos)))
        moveCaret(to: prev, extendSelection: extendSelection)
    }

    /// Moves caret forward by one grapheme cluster.
    public func moveRight(extendSelection: Bool = false) {
        if !extendSelection && !selection.isCollapsed {
            moveCaret(to: selection.range.upperBound)
            return
        }
        let pos = selection.caretPosition
        guard pos < text.count else { return }
        let next = text.distance(from: text.startIndex, to: text.index(after: stringIndex(for: pos)))
        moveCaret(to: next, extendSelection: extendSelection)
    }

    /// Moves caret to the beginning of the line or text.
    public func moveToBeginningOfLine(extendSelection: Bool = false) {
        let start = lineStartBoundary(from: selection.caretPosition)
        moveCaret(to: start, extendSelection: extendSelection)
    }

    /// Moves caret to the end of the line or text.
    public func moveToEndOfLine(extendSelection: Bool = false) {
        let end = lineEndBoundary(from: selection.caretPosition)
        moveCaret(to: end, extendSelection: extendSelection)
    }

    /// Moves caret to the previous word boundary.
    public func moveWordBackward(extendSelection: Bool = false) {
        let prev = previousWordBoundary(from: selection.caretPosition)
        moveCaret(to: prev, extendSelection: extendSelection)
    }

    /// Moves caret to the next word boundary.
    public func moveWordForward(extendSelection: Bool = false) {
        let next = nextWordBoundary(from: selection.caretPosition)
        moveCaret(to: next, extendSelection: extendSelection)
    }

    // MARK: - String Index & UTF-16 Bridging

    /// Converts a character count offset into a Swift `String.Index`.
    public func stringIndex(for offset: Int) -> String.Index {
        let clamped = min(max(0, offset), text.count)
        return text.index(text.startIndex, offsetBy: clamped)
    }

    /// Returns substring for a character offset range.
    public func substring(for range: Range<Int>) -> String {
        let clamped = min(max(0, range.lowerBound), text.count)..<min(max(0, range.upperBound), text.count)
        let s = stringIndex(for: clamped.lowerBound)
        let e = stringIndex(for: clamped.upperBound)
        return String(text[s..<e])
    }

    /// Converts a character offset to UTF-16 code unit offset.
    public func utf16Offset(for charOffset: Int) -> Int {
        let idx = stringIndex(for: charOffset)
        return text.utf16.distance(from: text.utf16.startIndex, to: idx.samePosition(in: text.utf16) ?? text.utf16.endIndex)
    }

    /// Converts a UTF-16 code unit offset back to a character count offset.
    public func charOffset(for utf16Offset: Int) -> Int {
        let clamped16 = min(max(0, utf16Offset), text.utf16.count)
        let u16Idx = text.utf16.index(text.utf16.startIndex, offsetBy: clamped16)
        guard let sIdx = u16Idx.samePosition(in: text) else {
            return text.count
        }
        return text.distance(from: text.startIndex, to: sIdx)
    }

    /// Converts character range to Foundation `NSRange` in UTF-16 coordinates.
    public func utf16NSRange(for range: Range<Int>) -> NSRange {
        let uStart = utf16Offset(for: range.lowerBound)
        let uEnd = utf16Offset(for: range.upperBound)
        return NSRange(location: uStart, length: uEnd - uStart)
    }

    /// Converts Foundation `NSRange` in UTF-16 coordinates to character range.
    public func charRange(for nsRange: NSRange) -> Range<Int> {
        let cStart = charOffset(for: nsRange.location)
        let cEnd = charOffset(for: nsRange.location + nsRange.length)
        return cStart..<cEnd
    }

    // MARK: - Boundary Calculations

    private func lineStartBoundary(from pos: Int) -> Int {
        guard pos > 0 else { return 0 }
        let idx = stringIndex(for: pos)
        var current = text.index(before: idx)
        while current > text.startIndex {
            if text[current] == "\n" {
                return text.distance(from: text.startIndex, to: text.index(after: current))
            }
            current = text.index(before: current)
        }
        if text[text.startIndex] == "\n" {
            return 1
        }
        return 0
    }

    private func lineEndBoundary(from pos: Int) -> Int {
        guard pos < text.count else { return text.count }
        var current = stringIndex(for: pos)
        while current < text.endIndex {
            if text[current] == "\n" {
                return text.distance(from: text.startIndex, to: current)
            }
            current = text.index(after: current)
        }
        return text.count
    }

    private func previousWordBoundary(from pos: Int) -> Int {
        guard pos > 0 else { return 0 }
        var idx = stringIndex(for: pos)

        // Skip preceding whitespace
        while idx > text.startIndex {
            let prev = text.index(before: idx)
            if !text[prev].isWhitespace { break }
            idx = prev
        }

        // Skip preceding word characters
        while idx > text.startIndex {
            let prev = text.index(before: idx)
            if text[prev].isWhitespace { break }
            idx = prev
        }

        return text.distance(from: text.startIndex, to: idx)
    }

    private func nextWordBoundary(from pos: Int) -> Int {
        guard pos < text.count else { return text.count }
        var idx = stringIndex(for: pos)

        // Skip current word characters
        while idx < text.endIndex && !text[idx].isWhitespace {
            idx = text.index(after: idx)
        }

        // Skip following whitespace
        while idx < text.endIndex && text[idx].isWhitespace {
            idx = text.index(after: idx)
        }

        return text.distance(from: text.startIndex, to: idx)
    }
}
