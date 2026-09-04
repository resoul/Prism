# ADR 0011: Unified Input Events, FocusTree, and Synchronized Accessibility Tree

## Status
Accepted

## Context
Prism builds cross-platform declarative user interfaces targeting iOS, macOS, and tvOS without leaking platform-specific UI frameworks (`UIKit`, `AppKit`, `SwiftUI`) into its public API. Interactive components (such as buttons, inputs, toggles, cards, and forms) require:
1. A platform-neutral event propagation model with standard capturing, target, and bubbling phases, pointer/key/scroll payloads, and `stopPropagation()` / `preventDefault()` policies.
2. Reverse-z hit testing that takes clipping boundaries, zIndex hierarchies, sibling drawing order, and local coordinate conversion into account.
3. A parallel `FocusTree` built synchronously with the mounted hierarchy, supporting Tab navigation, explicit priority ordering, 2D spatial navigation for arrow keys/remote controllers, and reactive Flux state observation.
4. An accessibility semantic tree (`AccessibilityTree`) providing traits, hints, labels, values, actions, and test IDs, bridged to platform assistive technologies (`NSAccessibility` on macOS, `UIAccessibility` on iOS/tvOS) with strict invalidation upon node unmount to prevent stale activations.
5. Early access to accessibility tokens (`reduceMotion`, `increaseContrast`) in the environment.
6. A centralized keyboard shortcut registry with conflict diagnostics to prevent colliding hotkeys.

## Decision
1. **Public-Neutral Event System (`Sources/PrismCore/Events/Event.swift`):**
   - Encapsulates `EventPhase` (`.capturing`, `.atTarget`, `.bubbling`), `EventResult` (`.handled`, `.ignored`), `EventModifiers` (`.shift`, `.control`, `.option`, `.command`), `PointerType` (`.mouse`, `.touch`, `.pen`), and `PointerButton` (`.primary`, `.secondary`, `.auxiliary`).
   - Strongly typed payloads: `PointerEventData`, `KeyEventData`, `ScrollEventData`, and `FocusEventData`.
   - Traversal via `EventDispatcher`: executes capturing handlers down the ancestry chain, target handlers, then bubbling handlers up the chain, halting immediately upon `event.stopPropagation()`.
   - Hover and gesture tracking: tracks `currentlyHoveredNode` and automatically synthesizes `.pointerEnter` / `.pointerLeave` on movement, and synthesizes `.tap` on matching pointer down/up sequences.
2. **Reverse-z Hit Testing (`Sources/PrismCore/Events/HitTester.swift`):**
   - Dispatches from top zIndex to bottom, ordering equal-zIndex siblings by display order (last sibling on top).
   - Enforces clipping: if a parent is marked `.clipped()`, points outside its global frame prune the entire subtree.
   - Ignores invisible nodes (`opacity <= 0.001`).
3. **Reactive FocusTree & 2D Spatial Resolver (`Sources/PrismCore/Events/FocusTree.swift`):**
   - Backed by Flux `CurrentValueDistinct<ElementID?>` (`focusFlux`), enabling components and nodes to reactively observe focus state.
   - Provides synchronous `@MainActor` access (`currentFocus`) for event handling and Tab navigation.
   - Supports explicit `focusOrder` prioritizing fields before fallback top-to-bottom / left-to-right layout ordering.
   - Implements 2D geometric vector search for spatial direction navigation (`.up`, `.down`, `.left`, `.right`), selecting candidate centroids with minimal angular and Euclidean distance scores.
   - Guaranteed unmount safety: `nodeUnmounted(id:)` immediately resets focus to nil if the active node is unmounted.
4. **Synchronized Accessibility Tree (`Sources/PrismCore/Events/Accessibility.swift`):**
   - Automatically extracted from the live `MountedNode` hierarchy during host rendering.
   - Supports `AccessibilityTraits`, `AccessibilityActionKind`, labels, hints, and stable `testID`s.
   - Strict `testID` isolation: `testID` is purely for automated UI testing and developer assertions; it never leaks into user-facing localized text or accessibility screen readers.
   - Stale record protection: when a node is unmounted, its `AccessibilityElement` is invalidated; attempts to perform actions on stale records immediately fail.
5. **Platform Host Bridges (`HostNSView`, `HostUIView`):**
   - Forward native mouse, touch, scroll, and key interactions into `PrismHostEngine` without exposing AppKit/UIKit types in public API.
   - Support `findAccessibilityElement(byTestID:)` across platforms.
6. **Environment & Shortcuts:**
   - Added `reduceMotion: Bool` and `increaseContrast: Bool` to `LocalizationEnvironment`.
   - `KeyboardShortcutRegistry` records duplicate key + modifier combinations and surfaces `ShortcutConflict` diagnostics.

## Consequences
- **Positive:** Interactive components can receive tap, hover, key, and focus events across iOS and macOS through a unified, platform-neutral API.
- **Positive:** VoiceOver and automated UI tests have deterministic `testID` and semantic trait lookup without relying on fragile string matching.
- **Positive:** Stale focus and accessibility records cannot trigger zombie actions after unmounting.
- **Trade-off:** Spatial focus calculation evaluates candidate distances across focusable nodes, requiring linear evaluation of active focusable elements in the scene.
