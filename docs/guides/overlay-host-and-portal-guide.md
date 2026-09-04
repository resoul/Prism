# OverlayHost, Portal, and Component Testability Guide

This guide covers presenting floating overlays, modal dialogs, toasts, and tooltips using Prism's `OverlayHost` and `Portal`, configuring anchored geometry preferences, and leveraging stable test identifiers (`.testID`) for automated UI testing.

---

## 1. Overlay Tiers & Z-Ordering

`OverlayHost` provides 5 strictly ordered tiers rendered above base content:

| Layer Tier | Z-Index | Typical Content | Hit-Test Order | Clipping Policy |
| :--- | :--- | :--- | :--- | :--- |
| `.content` | 0 | Base application UI | 5th (Last) | Standard container clipping |
| `.floating` | 1000 | Popovers, tooltips, dropdown menus | 4th | `masksToBounds = false` (unclipped) |
| `.modal` | 2000 | Dialogs, action sheets, bottom sheets | 3rd | `masksToBounds = false` + backdrop |
| `.toast` | 3000 | Snackbars, transient notifications | 2nd | `masksToBounds = false` (unclipped) |
| `.debug` | 4000 | Inspectors, layout overlays | 1st (Top) | `masksToBounds = false` (unclipped) |

### Hit-Testing Precedence
`HitTester` evaluates layers in top-down order: `.debug` -> `.toast` -> `.modal` -> `.floating` -> `.content`.

When a modal is active with `blocksBackgroundPointer = true`, any pointer interaction outside the modal is absorbed by the semi-transparent backdrop layer, protecting background content from accidental activation.

---

## 2. Portal Projection

A `Portal` visually moves an element's backing `CALayer` into a target overlay tier while keeping its logical position in the component tree.

### Why Use Portals?
- **Escapes Container Clipping:** A tooltip or popover inside a clipped `ScrollArea` or card extends beyond the card's boundary without being cut off.
- **Preserves Tree Context:** Event bubbling, theme inheritance, environment values, and Flux state bindings remain linked to the logical parent.

### Usage

```swift
import PrismUI
import PrismCore

struct CardWithTooltip: Component {
    func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 8) {
            Text("Card Heading")

            // Visual layer is projected into .floating overlay tier,
            // escaping the card's clipped boundary
            Portal(layer: .floating) {
                Text("Helpful Tooltip")
                    .background(Color.black)
                    .padding(8)
            }
        }
        .clipped()
        .frame(width: 200, height: 120)
    }
}
```

Or using the `.portal(layer:)` modifier:

```swift
Text("Floating Banner")
    .portal(layer: .floating)
```

---

## 3. Anchored Positioning & Preferences

Popovers and tooltips often need to align relative to an interactive trigger element.

### Declaring an Anchor
Mark any element as an anchor using `.anchor(id:)`:

```swift
Button("More Options")
    .anchor(id: "options_button")
```

### Presenting an Anchored Overlay

```swift
let popoverEntry = OverlayEntry(
    id: ElementID(typeName: "OptionsPopover"),
    layer: .floating,
    node: popoverMountedNode,
    positioning: .anchored(
        anchorID: "options_button",
        edge: .bottom,
        alignment: .center,
        offset: 8
    )
)

engine.overlayHost.present(popoverEntry)
```

### Invalidation & Cleanup
- **Scroll & Resize:** Calling `engine.invalidateOverlayPositions()` automatically updates all active anchored overlays to match current anchor positions.
- **Anchor Unmounting:** If the anchor element is unmounted from the tree, any overlay anchored to it is automatically dismissed with reason `.anchorUnmounted`.

---

## 4. Modal Lifecycle & Focus Trapping

Modals manage user focus and backdrop interactions systematically.

### Presentation & Focus Transfer
1. When `overlayHost.present(modalEntry)` is called with `layer: .modal`:
   - Active focus is saved (`entry.previousFocusID = engine.focusTree.currentFocus`).
   - Focus is automatically transferred to the first focusable child inside the modal.
   - The semi-transparent backdrop layer is shown.

### Dismissal & Focus Restoration
When the modal dismisses, focus is automatically restored to `previousFocusID`:

```swift
// Dismiss reasons:
// - .backdropTap: User tapped outside modal on backdrop
// - .escapeKey: User pressed Escape
// - .explicitClose: Programmatic close
// - .anchorUnmounted: Associated anchor disappeared
// - .timeout: Transient timer expired
engine.overlayHost.dismiss(id: modalID, reason: .explicitClose)
```

---

## 5. Component Testability (`.testID`)

Automated UI tests require stable selectors that do not change when user-facing text is translated or when layout containers are refactored.

### Assigning Stable Test IDs

```swift
Button("Submit Order")
    .testID("order_submit_button")
    .accessibilityLabel("Submit your purchase")
```

### Querying in UI Tests

```swift
let element = engine.accessibilityTree.findElement(byTestID: "order_submit_button")
XCTAssertNotNil(element)
XCTAssertEqual(element?.label, "Submit your purchase")
```

### Development Diagnostics for Conflicts
Prism provides built-in diagnostics to detect duplicate test IDs during development:

```swift
let conflicts = engine.testIDConflicts
if !conflicts.isEmpty {
    for conflict in conflicts {
        print("Warning: Duplicate testID '\(conflict.testID)' on elements \(conflict.elementIDs)")
    }
}
```
