# Text Editing and Form Controls Guide

This guide describes how to use Prism's CoreText-based text editing engine, focus scopes, two-way bindings, validation, and P1 interactive data entry controls.

---

## 1. Overview and Architecture

Prism implements a self-contained, pure CoreText-driven text editing engine completely decoupled from `UITextField`, `UITextView`, `NSTextField`, or `NSTextView`.

```
┌─────────────────────────────────────────────────────────┐
│                    PrismUI Components                   │
│   Input, Textarea, Button, Checkbox, RadioGroup, etc.   │
├─────────────────────────────────────────────────────────┤
│                   State & Validation                    │
│          Binding<Value>, ValidationRule, Form           │
├─────────────────────────────────────────────────────────┤
│                Text Editing Engine                      │
│   TextDocument, TextSelection, TextEditorMetrics        │
├─────────────────────────────────────────────────────────┤
│                Rendering & Animation                    │
│   TextEditorRenderer (CoreText lines, Caret, Selection) │
├─────────────────────────────────────────────────────────┤
│              Platform Input Adaptation                  │
│   PlatformTextInputAdapter (IME / NSTextInputClient)    │
└─────────────────────────────────────────────────────────┘
```

Key characteristics:
- **Zero Platform UI Leaks:** No `AppKit` or `UIKit` editor controls are exposed or embedded in the render tree.
- **CoreText Layout & Hit-Testing:** Character bounding boxes, line fragments, caret placement, and point-to-index hit-testing are measured mathematically via CoreText.
- **Pure CALayer Rendering:** Caret, selection highlights, placeholder, and text run on specialized sublayers with implicit action suppression.
- **IME & Unicode Ready:** Composing marked text ranges and multi-byte UTF-16 character indices are handled transparently.

---

## 2. TextDocument and Editing Model

`TextDocument` manages text buffer mutations, selection state, and integration with Foundation `UndoManager`.

```swift
var doc = TextDocument(text: "Hello world")

// UTF-16 and Swift String index bridging
let selection = TextSelection(range: 6..<11) // "world"
doc.selection = selection

// Text replacement
doc.replaceSelection(with: "Prism") // "Hello Prism"

// Deletions
doc.deleteBackward() // Backspace
doc.deleteWordBackward() // Option+Backspace
doc.deleteToBeginningOfLine() // Cmd+Backspace

// Marked text for IME composition
doc.setMarkedText("こんにちは", selectedRange: NSRange(location: 0, length: 5))
doc.unmarkText()
```

### Undo & Redo Boundaries
`TextDocument` optionally binds to Foundation's `UndoManager`:
- Each edit registers an inverse closure on the undo stack.
- Grouping undo transactions preserves caret selection before and after operations.

---

## 3. Platform Input Adaptation

Prism adapts native platform text input without exposing platform view hierarchies:
- **macOS:** `HostNSView` conforms to `NSTextInputClient`, forwarding input calls to `PlatformTextInputAdapter`.
- **Composing/Marked Text:** Underlined or highlighted IME composition states are passed down to `TextDocument` and rendered with dedicated styling.
- **Clipboard Actions:** Standard shortcuts (Cmd+C, Cmd+X, Cmd+V) interact with system pasteboards safely.
- **Password Masking:** `.password` input mode renders secure bullet characters (`•`) while maintaining the raw value in memory.

---

## 4. Focus Scopes and Keyboard Submission

Prism provides hierarchical focus scopes and keyboard submission handlers:

```swift
VStack {
    Input(placeholder: "Search...", text: $query)
        .submitLabel(.search)
        .onSubmit {
            performSearch(query)
        }
}
.focusScope("search-panel")
```

### Focus Restoration
When dialogs, sheets, or popups dismiss, `FocusScopeManager` automatically restores focus to the previously active element within the enclosing scope.

---

## 5. Form Controls and Data Entry

All P1 interactive controls reside in `PrismUI` under `Sources/PrismUI/DataEntry/`:

### Input
Single-line editable text field supporting input modes, placeholder, disabled, and error states:
```swift
Input(
    placeholder: "user@example.com",
    text: $email,
    mode: .email
)
```

### Textarea
Multi-line editable text area with vertical scrolling:
```swift
Textarea(
    placeholder: "Enter details...",
    text: $bio,
    rows: 4
)
```

### Button
Action button supporting standard variants (`.primary`, `.secondary`, `.danger`, `.ghost`) and sizes (`.sm`, `.md`, `.lg`):
```swift
Button("Save Changes", variant: .primary, size: .md) {
    saveProfile()
}
```

### Checkbox
Standard toggleable checkbox control with boolean binding:
```swift
Checkbox("Accept terms and conditions", isChecked: $termsAccepted)
```

### RadioGroup
Single-selection group for mutually exclusive options:
```swift
RadioGroup(
    selection: $plan,
    options: [
        ("free", "Free Plan"),
        ("pro", "Pro Plan"),
        ("enterprise", "Enterprise")
    ]
)
```

### Switch
Sliding boolean toggle switch:
```swift
Switch("Enable notifications", isOn: $notificationsEnabled)
```

### Toggle
Two-state push button toggle:
```swift
Toggle("Bold", isOn: $isBold)
```

---

## 6. Field Wrappers and Forms

`Field` wraps interactive controls with labels, required indicators, helper text, and validation error messages.

```swift
Form {
    Field(
        label: "Email Address",
        helperText: "We will never share your email.",
        error: emailError,
        isRequired: true
    ) {
        Input(placeholder: "you@domain.com", text: $email, mode: .email)
    }

    Field(label: "Bio") {
        Textarea(placeholder: "Tell us about yourself", text: $bio)
    }

    Button("Submit", variant: .primary) {
        submitForm()
    }
}
.onSubmit {
    submitForm()
}
```

---

## 7. Data Validation

Prism provides pure, composable validation rules:

```swift
let rules: [ValidationRule<String>] = [
    .required(message: "Email is required"),
    .email(message: "Please enter a valid email"),
    .maxLength(100, message: "Email is too long")
]

let result = ValidationResult.validate(email, with: rules)
if !result.isValid {
    print("Errors: \(result.errors)")
}
```
