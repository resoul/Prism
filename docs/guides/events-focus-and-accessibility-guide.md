# Events, Focus, and Accessibility Guide

This guide describes how to handle input events, manage keyboard and spatial focus, declare accessibility semantics, and configure accessibility environment tokens in Prism.

---

## 1. Unified Event System

Prism translates native platform input events (touch, mouse, keyboard, scroll) into pure, platform-neutral `Event` instances without leaking platform-specific framework types.

### Event Phases
Events propagate using standard three-phase dispatch:
1. **Capturing Phase (`.capturing`):** Traversing down from the root to the target node's parent.
2. **Target Phase (`.atTarget`):** Executing handlers registered on the hit target.
3. **Bubbling Phase (`.bubbling`):** Traversing up from the target node's parent back to the root.

```swift
node.addHandler(for: .tap, phase: .capturing) { event in
    // Intercept event during capturing phase
}

node.addHandler(for: .tap, phase: .bubbling) { event in
    // Process event during bubbling phase
}
```

### Halting Traversal
- `event.stopPropagation()` immediately stops propagation along subsequent phases and ancestors.
- `event.preventDefault()` notifies host engines to suppress native default actions.

---

## 2. Hit Testing & Reverse-z Ordering

Hit testing locates the interactive element under pointer coordinates:
- **Reverse-z:** Subtrees with higher `zIndex` are evaluated before lower `zIndex` elements. Tied `zIndex` siblings evaluate in reverse display order (later siblings on top).
- **Clipping Boundaries:** If an element is modified with `.clipped()`, points outside its bounding box cannot hit any of its children.
- **Invisibility:** Elements with `opacity <= 0.001` are ignored during hit testing.

---

## 3. Focus Management (`FocusTree`)

The `FocusTree` maintains active focus and enables Tab order and directional navigation.

### Focusable Elements
Mark elements as focusable and optionally specify their Tab priority:

```swift
let button = Text("OK")
    .focusable(true, order: 1)
```

### Tab and 2D Spatial Navigation
- **Tab Navigation (`moveFocus(direction: .next)` / `.previous`):** Focuses elements according to their `order` priority, falling back to layout position (top-to-bottom, left-to-right).
- **2D Spatial Navigation (`moveFocus(direction: .up | .down | .left | .right`):** Uses Euclidean centroid distances and angular weighting to move focus along directional vectors for keyboard arrow keys and remote controls.

### Reactive Focus Subscription
Focus state is backed by Flux `CurrentValueDistinct`:

```swift
node.bind(to: hostEngine.focusTree.currentFocusState) { node, focusedID in
    let isFocused = (node.id == focusedID)
    // update visual presentation
}
```

### Stale Focus Cleanup
When a mounted node is unmounted, `FocusTree` automatically resets focus to `nil` if the unmounted element had active focus, preventing focus leaks.

---

## 4. Accessibility Tree (`AccessibilityTree`)

Prism constructs a parallel semantic accessibility tree for assistive technologies and automated testing:

```swift
let field = Text("Email")
    .accessibilityLabel("Email Address")
    .accessibilityHint("Enter your account email")
    .accessibilityTraits([.searchField])
    .testID("email_input_field")
```

### Stable UI Test Identification (`testID`)
The `testID` attribute is strictly isolated:
- It **never** leaks into user-facing localized strings.
- It **never** changes across language or locale shifts.
- It is indexed for fast lookup in tests and platform bridges:
  ```swift
  let element = hostView.findAccessibilityElement(byTestID: "email_input_field")
  ```

### Stale Record Protection
When a component unmounts, its corresponding `AccessibilityElement` is invalidated. Subsequent attempts to invoke `performAction(.activate)` on unmounted records return `false`.

---

## 5. Keyboard Shortcuts & Conflicts

Register hotkeys with `KeyboardShortcutRegistry`:

```swift
let shortcut = KeyboardShortcut(key: "s", modifiers: .command)
hostEngine.shortcutRegistry.register(shortcut: shortcut, elementID: button.id) {
    saveDocument()
}
```

If multiple components register identical hotkey combinations, `shortcutRegistry.conflicts` logs structured `ShortcutConflict` diagnostic records.

---

## 6. Environment Accessibility Tokens

Prism exposes system accessibility preferences in `LocalizationEnvironment`:

```swift
let env = context.environment
if env.reduceMotion {
    // Disable or simplify animations
}
if env.increaseContrast {
    // Apply higher contrast border or color
}
```
