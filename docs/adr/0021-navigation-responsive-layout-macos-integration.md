# ADR 0021: Navigation, Responsive Layout, and macOS Window Integration

## Status
Accepted

## Context
Cross-platform modern desktop and mobile applications built with Prism require navigation routing, responsive layout scaling, and native platform window/menu integration while upholding strict architectural invariants:
1. **Module & Thread Isolation:** Navigation logic, route matching, and state restoration must be decoupled from storage layers (`PrismUI` must never import `PrismStorage` or `PrismData`). UI mutations occur on the MainActor, while navigation state remains pure, serializable data.
2. **Platform UI Isolation:** Desktop and mobile integration (toolbars, menu items, window groups) must not leak platform-specific types (`NSView`, `NSWindow`, `NSMenu`, `UIView`, `UIViewController`) into public API surfaces.
3. **Deep Linking & Fallback Safety:** Universal links and custom schemes (`prism://...`) must parse into canonical routes with parameter extraction (`:id`, `*wildcard`, query items) and safe fallback handling (404 screen) without crashing or inconsistent stack states.
4. **Adaptive & Responsive Layout:** UIs must adapt dynamically across phones, tablets, foldables, and desktop displays through container-driven breakpoints (`compact`, `medium`, `expanded`, `wide`) without hardcoding device models or screen orientations.
5. **Robust Scaffold & State Restoration:** Top bars, bottom bars, sidebars, and safe-area insets must compose declaratively with automatic scrolling support, and navigation state must survive app termination through versioned snapshot restoration.

## Decision

1. **Pure Route Pattern Matching & Deep Link Resolution:**
   - `RouteParameters`: Value type encapsulating path parameters (`:param`), query items (`?key=val`), and wildcard tokens (`*`).
   - `RoutePattern`: Pattern matcher supporting literal segments, named parameter captures, and wildcard segments.
   - `Route`: Named route definition mapping a pattern to a `ScreenBuilder` factory.
   - `Router`: Pure registry resolving URLs and paths to matched routes with fallback to a registered or default 404 handler.
   - `DeepLinkResolver`: Parser translating custom schemes (`prism://...`) and Universal Links (`https://...`) into normalized paths and query bags.

2. **Versioned Navigation Stack & Navigator:**
   - `RouteEntry`: Pure Codable data record capturing route identity, path, parameters, and route-scoped state.
   - `NavigationState`: Versioned (`currentVersion = 1`), serializable snapshot of the active navigation stack.
   - `Navigator`: Stack controller managing `push`, `pop`, `replace`, `reset`, and restoration, publishing transitions reactively via `Flux<NavigationState>`. Root pop boundary is safe (no-op returning `false`).
   - State restoration drops unmigratable or unroutable entries safely, falling back to a specified fallback path.
   - `NavigatorView`: Declarative component rendering the active route with customizable transitions (`.push`, `.modal`, `.fade`, `.none`).

3. **Responsive Layout Subsystem:**
   - `Breakpoint`: Container-derived width classification (`compact` <600pt, `medium` 600–900pt, `expanded` 900–1200pt, `wide` >1200pt).
   - `ResponsiveValue<T>`: Declarative value cascading downwards through breakpoints (`wide` -> `expanded` -> `medium` -> `compact`).
   - `ResponsiveContainer`: Container component reading available geometry and rendering content with current `Breakpoint`.
   - `.visible(on:)` and `.hidden(on:)` component modifiers for conditional breakpoint-driven visibility.

4. **Turnkey Scaffold:**
   - `Scaffold`: High-level layout component with declarative named slots (`topBar`, `bottomBar`, `sidebar`, `overlay`, `content`).
   - `SafeAreaPolicy`: Policy governing how insets are applied to content (`.all`, `.none`, `.topOnly`, `.bottomOnly`, `.horizontalOnly`).
   - `AutoScrollPolicy`: Policy automatically embedding content into a `ScrollArea` (`.automatic`, `.always`, `.never`).
   - Adapts slots responsively (e.g. sidebar on wide/expanded, bottomBar on compact).

5. **macOS Thin Bridge:**
   - `ToolbarItem` and `ToolbarPlacement`: Semantic declarative toolbar items (`.primaryAction`, `.status`, `.navigation`, etc.).
   - `MenuCommand`: Declarative menu hierarchy model (`file`, `edit`, `view`, `window`, `help`) with key equivalents without AppKit dependencies.
   - `WindowGroup` and `WindowManager`: Multi-window management models capturing window identifiers, titles, default sizes, and opening/closing commands.

6. **Decoupled State Restoration in Umbrella `Prism`:**
   - `NavigationStateStore` abstract protocol in `PrismUI`.
   - `PrismStorageNavigationStore` in the umbrella `Prism` module bridges `NavigationState` to `Preferences`, maintaining clean layer separation in conformance with `MODULE_CONTRACT.md`.

## Consequences
- **Positive:** Complete cross-platform navigation and responsive layout architecture without leaking platform UI types.
- **Positive:** Strict adherence to `MODULE_CONTRACT.md`: zero storage dependencies in `PrismUI`.
- **Positive:** Deterministic deep link resolution and stack state restoration resilient to route changes and version mismatches.
- **Positive:** Rich adaptive scaffolds capable of switching between mobile bottom navigation and desktop sidebar layouts effortlessly.
