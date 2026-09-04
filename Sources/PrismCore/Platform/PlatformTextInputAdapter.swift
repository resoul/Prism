import Foundation
import CoreGraphics
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Platform-internal text input bridge coordinating IME marked text, clipboard actions,
/// key navigation, and system text input protocols without exposing platform types in public API.
@MainActor
public final class PlatformTextInputAdapter: @unchecked Sendable {
    public static let shared = PlatformTextInputAdapter()

    public weak var activeDocument: TextDocument?
    public var activeElementID: ElementID?

    public init() {}

    /// Activates text editing for the specified document and element.
    public func activate(document: TextDocument, elementID: ElementID) {
        self.activeDocument = document
        self.activeElementID = elementID
    }

    /// Deactivates text editing.
    public func deactivate(for elementID: ElementID? = nil) {
        if let id = elementID, activeElementID != id {
            return
        }
        self.activeDocument = nil
        self.activeElementID = nil
    }

    // MARK: - Clipboard Operations

    /// Copies the currently selected text to the system clipboard.
    public func copy() {
        guard let doc = activeDocument, !doc.selection.isCollapsed else { return }
        let selectedText = doc.substring(for: doc.selection.range)

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(selectedText, forType: .string)
        #elseif os(iOS) && canImport(UIKit)
        UIPasteboard.general.string = selectedText
        #endif
    }

    /// Cuts the currently selected text to the system clipboard.
    public func cut() {
        copy()
        activeDocument?.deleteBackward()
    }

    /// Pastes text from the system clipboard into the active document.
    public func paste() {
        guard let doc = activeDocument else { return }

        let clipboardText: String? = {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSPasteboard.general.string(forType: .string)
            #elseif os(iOS) && canImport(UIKit)
            return UIPasteboard.general.string
            #else
            return nil
            #endif
        }()

        if let str = clipboardText, !str.isEmpty {
            doc.insert(str)
        }
    }

    // MARK: - Key Event Handling

    /// Handles keyboard events, returning true if the key event was consumed by the editor.
    public func handleKey(
        key: String,
        keyCode: UInt16,
        modifiers: EventModifiers,
        isRepeat: Bool
    ) -> Bool {
        guard let doc = activeDocument else { return false }

        let isCmd = modifiers.contains(.command)
        let isShift = modifiers.contains(.shift)
        let isOpt = modifiers.contains(.option)

        // Command shortcuts
        if isCmd {
            switch key.lowercased() {
            case "a":
                doc.selectAll()
                return true
            case "c":
                copy()
                return true
            case "v":
                paste()
                return true
            case "x":
                cut()
                return true
            case "z":
                if isShift {
                    doc.undoManager?.redo()
                } else {
                    doc.undoManager?.undo()
                }
                return true
            default:
                break
            }
        }

        // Arrow keys and text navigation (macOS keycodes: Left=123, Right=124, Down=125, Up=126, Return=36, Backspace=51, Delete=117)
        switch keyCode {
        case 51: // Backspace
            if isCmd {
                doc.deleteToBeginningOfLine()
            } else if isOpt {
                doc.deleteWordBackward()
            } else {
                doc.deleteBackward()
            }
            return true

        case 117: // Forward Delete
            doc.deleteForward()
            return true

        case 36: // Return / Enter
            doc.onSubmit?()
            return true

        case 123: // Left Arrow
            if isCmd {
                doc.moveToBeginningOfLine(extendSelection: isShift)
            } else if isOpt {
                doc.moveWordBackward(extendSelection: isShift)
            } else {
                doc.moveLeft(extendSelection: isShift)
            }
            return true

        case 124: // Right Arrow
            if isCmd {
                doc.moveToEndOfLine(extendSelection: isShift)
            } else if isOpt {
                doc.moveWordForward(extendSelection: isShift)
            } else {
                doc.moveRight(extendSelection: isShift)
            }
            return true

        default:
            break
        }

        // Plain text entry
        if !isCmd && !modifiers.contains(.control) && !key.isEmpty && key != "\t" && key != "\r" {
            doc.insert(key)
            return true
        }

        return false
    }

    // MARK: - NSTextInputClient & IME Bridging Helpers

    public func insertText(_ string: String, replacementRange: NSRange = NSRange(location: NSNotFound, length: 0)) {
        guard let doc = activeDocument else { return }
        if replacementRange.location != NSNotFound {
            let charRange = doc.charRange(for: replacementRange)
            doc.replace(range: charRange, with: string)
        } else {
            doc.insert(string)
        }
    }

    public func setMarkedText(_ string: String, selectedRange: NSRange, replacementRange: NSRange = NSRange(location: NSNotFound, length: 0)) {
        guard let doc = activeDocument else { return }
        let selRange = (selectedRange.location != NSNotFound) ? (selectedRange.location..<(selectedRange.location + selectedRange.length)) : nil
        doc.setMarkedText(string, selectedRange: selRange)
    }

    public func unmarkText() {
        activeDocument?.unmarkText()
    }

    public var selectedRange: NSRange {
        guard let doc = activeDocument else { return NSRange(location: NSNotFound, length: 0) }
        return doc.utf16NSRange(for: doc.selection.range)
    }

    public var markedRange: NSRange {
        guard let doc = activeDocument, let m = doc.markedRange else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return doc.utf16NSRange(for: m)
    }

    public var hasMarkedText: Bool {
        activeDocument?.hasMarkedText ?? false
    }
}
