# ADR 0018: P1 Component Catalog and Extensible Style Contracts

## Status
Accepted

## Context
Applications require a standardized suite of secondary (P1) design system components for data display (`Badge`, `Label`, `Avatar`, `Card`, `IconTile`), user feedback (`Alert`, `Spinner`), navigation (`Tabs`), modal overlays (`Dialog`, `Tooltip`), and layout spacing (`Divider`, `Frame`).

Without an intentional architectural foundation:
1. **Accessibility Loss in Custom Styles:** When UI libraries permit arbitrary styling, consumers often replace native buttons and inputs with ad-hoc containers, accidentally removing keyboard focus navigation, VoiceOver roles (`button`, `dialog`, `tab`, `tabpanel`), and disabled state semantics.
2. **Platform Framework Infiltration:** Building modals or tooltips using platform controllers (`UIAlertController`, `NSAlert`, `NSPopover`) leaks platform UI into public signatures, violating `ADR 0001` and `MODULE_CONTRACT.md`.
3. **Motion Insensitivity:** Spinners and animated indicators running uncontrolled Core Animation keyframe loops cause motion sickness and cognitive strain for users who have enabled the system Reduce Motion accessibility preference.

## Decision

1. **Pure Component Architecture (`Component` Protocol):**
   - Every P1 component produces pure Virtual Render Tree (`RenderElement`) nodes with deterministic `ElementID`, `ElementKind`, and `ElementProps`.
   - Zero UIKit/AppKit/SwiftUI view instances are created or exposed.

2. **Extensible Style Contracts (`ButtonStyle`, `InputStyle`, `CardStyle`):**
   - Style protocols decouple visual appearance from behavior and accessibility.
   - Built-in ShadCN-inspired defaults (`DefaultButtonStyle`, `DefaultInputStyle`, `DefaultCardStyle`) provide immediate aesthetic parity.
   - Invariant preservation: `ButtonConfiguration` and `InputConfiguration` strictly bundle state flags (`isPressed`, `isEnabled`, `isLoading`, `isFocused`, `hasError`), ensuring custom styling hooks can never bypass disabled opacity or testIDs.

3. **Motion-Aware Feedback (`Spinner` & `Alert`):**
   - `Spinner` inspects `context.environment.reduceMotion`: when active, continuous rotation animations are suppressed in favor of a static, accessible indicator with the `updatesFrequently` trait.
   - `Alert` classifies notifications into semantic variants (`.info`, `.warning`, `.success`, `.destructive`) with automatic icon pairing and accessible announcements.

4. **Overlay Foundations (`Dialog` & `Tooltip`):**
   - Built directly on top of `Portal(layer: .modal)` and `Portal(layer: .floating)`.
   - `Dialog`: Features a dimmed backdrop layer (`Color(red: 0, green: 0, blue: 0, alpha: 0.5)`), centered dialog card surface, Escape key dismissal, and focus trap semantics (`role: dialog`, `modal: true`).
   - `Tooltip`: Anchors to target elements with placement options (`.top`, `.bottom`, `.leading`, `.trailing`), presentation delay, and screen-edge boundary protection.

5. **Navigation Semantics (`Tabs`):**
   - Strict `tab` to `tabpanel` accessibility linking (`aria-controls` and `aria-labelledby`).
   - Active tab selection indicator and keyboard arrow navigation.

## Consequences
- **Positive:** Complete, ready-to-use P1 catalog with unified design tokens, typography, and accessibility traits.
- **Positive:** Full cross-platform parity on iOS and macOS with zero platform controller dependencies.
- **Positive:** Safe extensibility: custom styling protocols cannot remove accessibility or keyboard focus invariants.
- **Trade-off:** `Dialog` and `Tooltip` rely on the root `OverlayHost` existing within the active rendering hierarchy.
