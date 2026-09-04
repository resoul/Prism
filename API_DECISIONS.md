# Prism — Core API Decisions & Architectural Invariants

This document formalizes foundational architectural decisions for Prism across all modules.

---

## 1. Element Identity Model

Virtual Render Tree (VRT) nodes and reconciler reconciliation rely on a three-tuple identity:
$$\text{Identity} = (\text{Type}, \text{Explicit Key}, \text{Sibling Position})$$

- **Type (`typeName`)**: The concrete component or element kind (e.g. `Text`, `Stack`, `Button`).
- **Explicit Key (`key`)**: Optional user-provided string key for stable identity across list/reorder updates.
- **Sibling Position (`siblingIndex`)**: Structural position relative to siblings when an explicit key is omitted.

```swift
public struct ElementID: Hashable, Sendable, CustomStringConvertible {
    public let typeName: String
    public let key: String?
    public let siblingIndex: Int
}
```

**Invariant:** Collections (`LazyList`, `LazyGrid`) require stable keys for server data. Array indices must never serve as persistent identities for dynamic data items.

---

## 2. CALayer Ownership & MainActor Boundary

- **Host View as Mount Root:** `UIView` (iOS/tvOS) and `NSView` (macOS) exist solely as host bridges in `PrismCore/Platform/`. They provide window attachment, backing layers, and native event forwarding.
- **Strict Layer Ownership:** `CALayer` instances are owned strictly by `MountedNode` hierarchies inside the renderer layer. Host views do not own child element layers.
- **MainActor Confinement:** All mutations to `CALayer`, host views, mounted trees, focus engine state, and accessibility adapters MUST occur on `@MainActor`.
- **Background Preparation:** Immutable data preparation, layout measure computation, and image/data decoding are performed off the main thread before committing to the mounted tree on `@MainActor`.

---

## 3. Error Model

- **Errors are State, Not Log Artifacts:**
  - Initial load failures, refresh failures, and append/pagination failures are represented as distinct states in stores and component inputs (e.g., `Loadable<T>`, `PaginationState<T>`).
  - Network and persistence failures do not crash the UI and are not silently discarded in logs.
- **Predictable Error Boundaries:**
  - Rendering and reconciliation errors fallback gracefully without tearing down the host window.

---

## 4. Naming Conventions

- **Components:** Named as declarative nouns or verbs (e.g., `Text`, `Stack`, `Button`, `ScrollArea`, `CollapsingTabPager`).
- **Modifiers:** Method chaining returning `RenderElement` (e.g., `.padding(...)`, `.background(...)`, `.cornerRadius(...)`).
- **Tokens:** Semantic tokens organized by role (e.g., `.theme(.background)`, `.theme(.spacing.md)`, `.theme(.radius.lg)`), never raw magic hex or point literals.
- **Markers & Protocols:** Suffix with `Contract` or `Protocol` for module boundaries (e.g., `StorageContract`, `DataRepositoryContract`).

---

## 5. Platform UI Abstraction (No UIKit/AppKit/SwiftUI in Public API)

- **Strict Encapsulation:** Public APIs exposed by `Prism`, `PrismUI`, `PrismCore`, `PrismData`, `PrismStorage`, and `PrismLogging` must never leak `UIView`, `UIViewController`, `NSView`, `NSViewController`, `SwiftUI.View`, or Metal types directly into consumer signatures.
- Platform-specific bridging is encapsulated strictly within `PrismCore/Platform/`.
