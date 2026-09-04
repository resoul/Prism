# Navigation, Responsive Layout, and macOS Integration Guide

Prism provides a declarative, cross-platform navigation and responsive layout architecture tailored for phones, tablets, and desktop workstations.

This guide details route declaration, deep link handling, adaptive layout breakpoints, turnkey application scaffolds, and native desktop window/menu integration.

---

## Architecture & Boundary Invariants

1. **Zero UI Framework Leakage:**
   - Platform UI types (`NSView`, `NSWindow`, `NSMenu`, `UIView`, `UIViewController`) are never exposed in public API contracts.
   - Declarative descriptors (`ToolbarItem`, `MenuCommand`, `WindowGroup`) model native capabilities cleanly.
2. **Strict Module Boundaries (`MODULE_CONTRACT.md`):**
   - `PrismUI` does not import `PrismStorage` or `PrismData`.
   - `NavigationStateStore` is an abstract interface in `PrismUI`.
   - Turnkey persistence is provided in the umbrella `Prism` module via `PrismStorageNavigationStore`.
3. **Safe Stack Transitions & Deep Links:**
   - Pop operations at the root of the navigation stack are safe no-ops returning `false`.
   - Missing or unmigratable routes fail safely to a registered or default 404 screen without crashing.

---

## 1. Route Matching & Deep Links

### Defining Routes with `Router`

Routes support static paths, named parameters (`:id`), and wildcards (`*`):

```swift
import PrismUI

let router = Router()

// Static route
router.register("/home") { params in
    HomeScreen()
}

// Parameterized route
router.register("/profile/:id") { params in
    let profileID = params["id"] ?? "guest"
    ProfileScreen(id: profileID)
}

// Wildcard route
router.register("/files/*") { params in
    let path = params.wildcard ?? ""
    FileBrowserScreen(relativePath: path)
}
```

### Parsing Deep Links with `DeepLinkResolver`

`DeepLinkResolver` parses custom schemes and Universal Links into normalized paths and query bags:

```swift
let resolver = DeepLinkResolver(
    allowedSchemes: ["prism"],
    allowedHosts: ["app.prism.dev"]
)

// Universal Link: https://app.prism.dev/profile/42?tab=activity
if let (path, params) = resolver.resolve(universalLink: url) {
    // path: "/profile/42"
    // params.query["tab"]: "activity"
    navigator.push(path, parameters: params)
}
```

---

## 2. Navigation Stack & Restoration

### Managing the Stack with `Navigator`

The `Navigator` manages the active stack and publishes state updates reactively:

```swift
let navigator = Navigator(router: router, initialPath: "/home")

// Push
navigator.push("/profile/42")

// Pop (returns false if at root, preventing crashes)
let didPop = navigator.pop()

// Replace top
navigator.replace("/profile/43")

// Reset stack
navigator.reset(to: "/home")
```

### Rendering with `NavigatorView`

Mount the stack inside your component tree with customizable transitions:

```swift
NavigatorView(navigator: navigator)
```

### State Restoration (`PrismStorageNavigationStore`)

In the umbrella `Prism` package, navigation state can be saved and restored across launches:

```swift
import Prism

let store = PrismStorageNavigationStore()

// Save state on background / exit
await store.saveNavigationState(navigator.state)

// Restore state on launch
if let savedState = await store.loadNavigationState() {
    navigator.restore(savedState, fallbackPath: "/home")
}
```

---

## 3. Responsive Layout & Breakpoints

### Breakpoint Classification

Prism automatically computes container-driven breakpoints:
- `compact`: width < 600 pt (phones, split-views)
- `medium`: width 600–900 pt (tablets portrait, small desktop windows)
- `expanded`: width 900–1200 pt (tablets landscape, standard desktop windows)
- `wide`: width > 1200 pt (widescreen displays, multi-column desktop views)

### Cascading `ResponsiveValue<T>`

Define values that adapt smoothly across breakpoints with downward fallback:

```swift
let columns = ResponsiveValue<Int>(
    compact: 1,
    medium: 2,
    expanded: 3,
    wide: 4
)

// Resolves automatically to the appropriate breakpoint value
let currentColumns = columns.resolve(for: breakpoint)
```

### Breakpoint Modifiers

Conditionally display or hide components:

```swift
Text("Desktop Sidebar")
    .visible(on: [.expanded, .wide])

Text("Mobile Tab Bar")
    .hidden(on: [.expanded, .wide])
```

---

## 4. Turnkey `Scaffold`

Compose standard application layouts with named slots and safe area management:

```swift
Scaffold(
    safeAreaPolicy: .all,
    autoScrollPolicy: .automatic,
    topBar: NavigationBar(title: "Settings"),
    sidebar: DesktopSidebar().visible(on: [.expanded, .wide]),
    bottomBar: MobileTabBar().visible(on: [.compact]),
    content: SettingsContent()
)
```

---

## 5. macOS Desktop Integration

Integrate native desktop toolbars, menu bar items, and multiple windows without AppKit code:

```swift
// Native Toolbar Items
let searchItem = ToolbarItem(
    id: "search",
    title: "Search",
    iconName: "magnifyingglass",
    placement: .primaryAction
) {
    openSearch()
}

// Menu Commands
let newWindowCommand = MenuCommand(
    id: "new.window",
    title: "New Window",
    keyEquivalent: "n",
    modifiers: [.command]
) {
    WindowManager.shared.openWindow("main")
}

// Multi-Window Groups
let documentGroup = WindowGroup(
    id: "document",
    title: "Prism Document",
    defaultSize: CGSize(width: 1024, height: 768)
) { windowID in
    DocumentEditor(id: windowID)
}
```
