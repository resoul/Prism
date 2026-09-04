# ADR 0023: P2 Data Display and Layout Components

## Status
Accepted

## Context
Following the stabilization of the core VRT engine, layer renderer, navigation subsystem, and optional Metal effects, application authors require essential Phase 05 P2 primitives for rich content display, loading feedback, layout management, and disclosure interactions:
1. **Developer Ergonomics & Consistent Design Tokens:** Primitives must adhere strictly to design system semantic tokens (`ThemeColors`, `FontRole`, `Spacing`, `Radius`) with zero ad-hoc styling.
2. **Accessible Interaction & Motion Adaptations:** Components such as `Skeleton` must dynamically inspect `ReduceMotionPreference` to suppress pulsing shimmer under active Reduce Motion accessibility settings. Keycaps (`Kbd`) and tables (`Table`) must expose correct accessibility traits (`role: "keyboardKey"`, `role: "table"`, `role: "columnheader"`, `role: "cell"`).
3. **Safe Evaluation & Zero Script Execution:** Syntax snippet displays (`CodeBlock`) must render plain text securely without executing arbitrary code, script templates, or external interpreters.
4. **Performance Boundaries:** Static tables (`Table`) are designed for in-memory datasets up to ~1,000 rows. Very large virtualized datasets (10,000+ rows) are explicitly deferred to `LazyList` and future P3 `DataGrid` controls to prevent unvirtualized memory expansion.
5. **Overlay & Portal Integration:** Floating contextual previews (`HoverCard`) must seamlessly project into the `.floating` overlay tier via `Portal` while preserving logical VRT parentage.

## Decision

1. **Data Display Primitives in `PrismUI`:**
   - **`Kbd`:** Renders keycap badges with monospace typography, subtle borders, and semantic symbol mapping (e.g. `⌘` -> "Command", `⇧` -> "Shift", `↵` -> "Return").
   - **`CodeBlock`:** Formats multi-line code snippets with monospace font, optional line numbers, copy action button, and safe plain text rendering.
   - **`Table`:** Multi-column static table featuring `TableColumn`, `TableRow`, zebra striping, borders, and column text alignments (`.leading`, `.center`, `.trailing`).
   - **`Timeline`:** Vertical chronological milestone display with milestone dots (`.completed`, `.active`, `.upcoming`), connecting vertical lines, timestamps, and descriptions.
   - **`Empty`:** Turnkey empty state view with icon, title, description, and optional action button.

2. **Feedback & Disclosure Components:**
   - **`Skeleton`:** Shimmer and pulse placeholder loader supporting `.rounded(radius:)`, `.circle`, and `.rectangle` shapes. Automatically respects `context.environment.reduceMotion`: suppresses animations and displays a low-contrast static placeholder when active.
   - **`HoverCard`:** Contextual preview card anchored to trigger elements, projecting rich preview content into `OverlayLayer.floating` via `Portal`.
   - **`Accordion` & `Collapsible`:** Two-way binding (`Binding<Bool>`, `Binding<Set<String>>`) disclosure containers with smooth height/opacity transitions, keyboard accessibility, and `.single` / `.multiple` expansion modes.

3. **Layout Primitives:**
   - **`AspectRatio`:** Container enforcing fixed width-to-height ratio ($w / h$) with two-pass constraint evaluation (`.fit` and `.fill` modes) and `resolveSize(availableWidth:availableHeight:)` resolver.

4. **Dedicated Integration Demo:**
   - `P2DemoScreen`: Integrates all 9 components cohesively into an interactive showcase screen.

## Consequences
- **Positive:** Authors have a comprehensive catalog of P2 display and disclosure components without writing custom layer math.
- **Positive:** Strict accessibility compliance out of the box (Reduce Motion, screen reader roles).
- **Positive:** Zero platform UI leakage (`NSView`, `UIView`, `SwiftUI.View` remain completely internal).
- **Positive:** Clear performance boundaries documented between static `Table` and virtualized `LazyList`/`DataGrid`.
