import XCTest
import CoreGraphics
@testable import PrismCore

final class TextEditingTests: XCTestCase {

    // MARK: - Grapheme & UTF-16 Bridging

    @MainActor
    func testGraphemeAndUTF16Bridging() {
        // String with ASCII, accents, and multi-code-point emoji
        let text = "Hello 👨‍👩‍👧‍👦 World"
        let doc = TextDocument(text: text)

        XCTAssertEqual(doc.text, text)

        // Find character offset of "World"
        let worldOffset = doc.text.distance(from: doc.text.startIndex, to: doc.text.range(of: "World")!.lowerBound)
        let utf16Offset = doc.utf16Offset(for: worldOffset)

        // UTF-16 count of "Hello " (6) + emoji (👨‍👩‍👧‍👦 is 11 UTF-16 code units) + " " (1) = 18
        XCTAssertGreaterThan(utf16Offset, worldOffset)

        let convertedBack = doc.charOffset(for: utf16Offset)
        XCTAssertEqual(convertedBack, worldOffset)
    }

    // MARK: - Mutations & Selection Replacement

    @MainActor
    func testInsertAndDelete() {
        let doc = TextDocument(text: "Hello")
        doc.moveCaret(to: 5)
        doc.insert(" World")
        XCTAssertEqual(doc.text, "Hello World")
        XCTAssertEqual(doc.selection.caretPosition, 11)

        // Delete backward
        doc.deleteBackward()
        XCTAssertEqual(doc.text, "Hello Worl")
        XCTAssertEqual(doc.selection.caretPosition, 10)

        // Delete word backward
        doc.deleteWordBackward()
        XCTAssertEqual(doc.text, "Hello ")
        XCTAssertEqual(doc.selection.caretPosition, 6)

        // Selection replacement
        doc.selection = TextSelection(anchor: 0, active: 5)
        doc.insert("Hi")
        XCTAssertEqual(doc.text, "Hi ")
        XCTAssertEqual(doc.selection.caretPosition, 2)
    }

    @MainActor
    func testLineBoundaries() {
        let doc = TextDocument(text: "First line\nSecond line")
        doc.moveCaret(to: 18) // middle of "Second line"

        doc.moveToBeginningOfLine()
        XCTAssertEqual(doc.selection.caretPosition, 11)

        doc.moveToEndOfLine()
        XCTAssertEqual(doc.selection.caretPosition, 22)

        doc.deleteToBeginningOfLine()
        XCTAssertEqual(doc.text, "First line\n")
    }

    // MARK: - Undo & Redo Integration

    @MainActor
    func testUndoRedoIntegration() {
        let undo = UndoManager()
        let doc = TextDocument(text: "Initial", undoManager: undo)

        doc.insert(" Text")
        XCTAssertEqual(doc.text, "Initial Text")

        undo.undo()
        XCTAssertEqual(doc.text, "Initial")

        undo.redo()
        XCTAssertEqual(doc.text, "Initial Text")
    }

    // MARK: - Marked Text (IME)

    @MainActor
    func testMarkedTextLifecycle() {
        let doc = TextDocument(text: "Prefix ")
        doc.moveCaret(to: 7)

        doc.setMarkedText("nihon")
        XCTAssertTrue(doc.hasMarkedText)
        XCTAssertEqual(doc.text, "Prefix nihon")
        XCTAssertEqual(doc.markedRange, 7..<12)

        // Update marked text with conversion candidate
        doc.setMarkedText("日本")
        XCTAssertTrue(doc.hasMarkedText)
        XCTAssertEqual(doc.text, "Prefix 日本")
        XCTAssertEqual(doc.markedRange, 7..<9)

        // Unmark (commit)
        doc.unmarkText()
        XCTAssertFalse(doc.hasMarkedText)
        XCTAssertNil(doc.markedRange)
        XCTAssertEqual(doc.text, "Prefix 日本")
    }

    // MARK: - Password Masking

    func testPasswordMasking() {
        let raw = "SecretPassword123"
        let masked = TextInputMode.mask(text: raw)
        XCTAssertEqual(masked.count, raw.count)
        XCTAssertEqual(masked, "•••••••••••••••••")
        XCTAssertFalse(masked.contains("Secret"))
    }

    // MARK: - Validation Rules

    func testValidationRules() {
        let requiredRule = ValidationRule<String>.required()
        XCTAssertTrue(requiredRule.validate("Hello").isValid)
        XCTAssertFalse(requiredRule.validate("   ").isValid)

        let emailRule = ValidationRule<String>.email()
        XCTAssertTrue(emailRule.validate("user@example.com").isValid)
        XCTAssertFalse(emailRule.validate("not-an-email").isValid)

        let minLengthRule = ValidationRule<String>.minLength(5)
        XCTAssertTrue(minLengthRule.validate("12345").isValid)
        XCTAssertFalse(minLengthRule.validate("1234").isValid)
    }

    // MARK: - FocusScope Restoration

    @MainActor
    func testFocusScopePushAndRestore() {
        let manager = FocusScopeManager()
        let initialFocus = ElementID(typeName: "Input", key: "username")

        manager.pushScope(id: "dialogScope", currentFocus: initialFocus, trapsFocus: true)
        XCTAssertTrue(manager.currentScopeTrapsFocus)

        let restored = manager.popScope(id: "dialogScope")
        XCTAssertEqual(restored, initialFocus)
        XCTAssertFalse(manager.currentScopeTrapsFocus)
    }
}
