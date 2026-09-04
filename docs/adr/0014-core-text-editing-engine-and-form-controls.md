# ADR 0014: Core Text Editing Engine and Interactive Controls

## Status
Accepted

## Context
Interactive applications require text input (`Input`, `Textarea`), interactive buttons, toggles, checkboxes, radio selections, and form validation. In typical cross-platform UI frameworks, text fields are wrapped around platform controls (`UITextField` on iOS, `NSTextField` on macOS). This creates fundamental problems:
1. **Loss of visual control & styling inconsistency:** Platform fields bring system-dependent borders, focus rings, padding, and layout quirks that break custom design tokens and theme consistency.
2. **Platform UI leaks:** Exposing platform view objects or responders in public API violates `MODULE_CONTRACT.md` and ADR 0001.
3. **Reconciler & focus churn:** Reconciling virtual trees while bridging to external `UIView`/`NSView` text controls causes focus loss, caret jumping, and layout jitter.
4. **Input method complexity:** Native text editing requires full support for complex Unicode grapheme clusters, multi-stage Input Method Editor (IME) marked text composition (e.g. CJK, dead-key accents), clipboard integration, and Undo/Redo transactions.
5. **Security & password protection:** Secure inputs must never leak raw password characters to debug tree serialization, logging sinks, or crash reports.

## Decision
1. **Custom Text Editing Engine (`Sources/PrismCore/TextEditing/`):**
   - Pure Swift buffer `TextDocument` managing text mutations, grapheme cluster boundaries, UTF-16 code unit indexing, and selection ranges.
   - Support for IME multi-stage marked/composing text (`setMarkedText`, `unmarkText`, `hasMarkedText`).
   - Deep integration with Foundation `UndoManager`, registering reversible edit transactions.
   - `TextSelection` model supporting collapsed carets, selection ranges, drag expansion, and line-wrap affinity (`.upstream`, `.downstream`).
   - Typographic metrics engine (`TextEditorMetrics`) computing CoreText line fragments, character rects, point-to-character hit testing, and multi-line selection bounding boxes.

2. **Layer-Based Text Editor Renderer (`Sources/PrismCore/Rendering/TextEditorRenderer.swift`):**
   - Conforms to `LayerRenderer` and integrated into `RendererFactory`.
   - Dedicated sublayers: `textLayer` (`CATextLayer`), `selectionLayer` (`CAShapeLayer`), `caretLayer` (`CALayer`), `placeholderLayer` (`CATextLayer`).
   - Smooth 1.0s caret blinking animation (`CAKeyframeAnimation`), automatically paused and hidden when the editor loses focus.
   - Dynamic viewport scrolling: horizontal scroll tracking for single-line `Input`, vertical scroll tracking for multi-line `Textarea`.
   - Security masking: passwords automatically render standard bullet masks (`•`), preventing raw strings from appearing in layer dumps or logs.

3. **Platform Input Adapters (`Sources/PrismCore/Platform/PlatformTextInputAdapter.swift`):**
   - Internal bridge conforming to macOS `NSTextInputClient` in `HostNSView`, handling marked text, replacement ranges, and candidate windows.
   - Clipboard integration for cut, copy, and paste via `NSPasteboard` (macOS) and `UIPasteboard` (iOS).
   - Standard keyboard shortcuts: word jumping (Option+Arrow), line boundary jumps (Command+Arrow), selection expansion (Shift+Arrow), select all (Cmd+A), undo (Cmd+Z), redo (Cmd+Shift+Z).
   - Zero exposure of platform editor classes in public API.

4. **Focus Scoping & Restoration (`Sources/PrismCore/Events/FocusScope.swift`):**
   - `FocusScopeManager`: manages focus groups, Tab traversal trapping within dialogs or forms, and focus restoration to previously active elements upon overlay dismiss.
   - Declarative modifiers: `.onSubmit()`, `.submitLabel()`, and `.focusScope(id:trapsFocus:)`.

5. **Validation Contract & Interactive Controls (`Sources/PrismUI/DataEntry/`):**
   - `ValidationRule<Value>` (`.required`, `.email`, `.minLength`, `.maxLength`, `.custom`) and `ValidationResult`.
   - Standard P1 controls:
     - `Input`: single-line text input with placeholder, binding, clear/icon slots, disabled/read-only states.
     - `Textarea`: multi-line text input with min/max lines.
     - `Button`: interactive button with styles (`.primary`, `.secondary`, `.destructive`, `.outline`, `.ghost`), sizes (`.sm`, `.md`, `.lg`), disabled, and loading states.
     - `Checkbox`: accessible boolean toggle with checkmark and label.
     - `RadioGroup` & `RadioItem`: single-selection options.
     - `Switch`: sliding toggle switch.
     - `Toggle`: two-state toggle button.
     - `Field`: form field wrapper with label, required marker, helper text, and error indicators.
     - `Form`: form container coordinating group submit and validation.

## Consequences
- **Positive:** Complete cross-platform text editing without relying on `UITextField` or `NSTextField`.
- **Positive:** 100% theme-driven appearance matching design tokens, with sharp CoreAnimation rendering and smooth blinking caret.
- **Positive:** Password security guaranteed across debug tree serialization and structured logging.
- **Positive:** Full IME and native keyboard shortcut parity on macOS and iOS.
- **Positive:** Comprehensive P1 form control suite available in `PrismUI`.
- **Trade-off:** Rich text formatting (inline links, custom font spans) within the active editor is deferred to future P2/P3 releases; the editor currently manages plain text with unified font styling.
