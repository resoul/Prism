# Prism

> High-performance, declarative, cross-platform UI framework for Apple platforms.
> Supporting **iOS 16+**, **macOS 14+**, and **tvOS 17+**.
> Built on a custom layout engine and CALayer/Metal renderer — without SwiftUI, UIKit, or AppKit in the public API.

---

## Architectural Layers

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 5 — Component API (Public: PrismUI)                   │
│  Button, Card, Input, Text, Stack, ScrollArea...             │
└─────────────────────────┬────────────────────────────────────┘
                          │ produces immutable tree
┌─────────────────────────▼────────────────────────────────────┐
│  Layer 4 — Virtual Render Tree (VRT) & Reconciler            │
│  RenderElement (value type) -> Diff -> Patch MountedNode     │
│  Reactivity: Flux (CurrentValue / Pipe)                      │
└─────────────────────────┬────────────────────────────────────┘
                          │ layout pass
┌─────────────────────────▼────────────────────────────────────┐
│  Layer 3 — Layout Engine                                     │
│  Two-pass Flexbox-inspired: measure(available) -> layout(frame)│
└──────────────┬──────────────────────┬────────────────────────┘
               │                      │
┌──────────────▼──────┐  ┌────────────▼─────────────────────┐
│  Layer 2a           │  │  Layer 2b                        │
│  CALayer Renderer   │  │  Metal Renderer                  │
│  Core Text, layers  │  │  SDF Shaders, Blur, Glassmorphism│
└──────────────┬──────┘  └────────────┬─────────────────────┘
               └──────────┬───────────┘
┌──────────────────────────▼───────────────────────────────────┐
│  Layer 1 — Platform Bridge (Strictly Internal)               │
│  iOS / tvOS: UIView host                                     │
│  macOS:      NSView host                                     │
│  Unified Focus, Event, and Window abstractions               │
└──────────────────────────────────────────────────────────────┘
```

### Architectural Invariant: Platform UI Encapsulation
Platform host objects (`UIView`, `NSView`, `UIWindow`, `NSWindow`) are strictly confined to internal host adapters in `Sources/PrismCore/Platform/` and renderer internals. They are **never** exposed in public API contracts.

---

## Products & Selective Imports

Prism offers modular Swift Package products:

| Product | Description |
|---|---|
| `Prism` | Umbrella module. Exports `PrismUI`, `PrismData`, `PrismStorage`, `PrismLogging`, and `Flux`. |
| `PrismUI` | Declarative UI framework, components, layout, and theming. Does not include Data or Storage. |
| `PrismCore` | Low-level VRT, layout engine, renderer protocols, and event foundation. |
| `PrismData` | Network client, repositories, realtime protocols, and store contracts. |
| `PrismStorage` | Persistence layer: Preferences, SecureStore, FileStore, and Cache. |
| `PrismLogging` | Structured diagnostics, sinks (Console, OSLog, File), and telemetry contracts. |

```swift
// Standard application:
import Prism

// UI-only target (no data or persistence dependencies):
import PrismUI
```

---

## Installation

Add Prism as a Swift Package dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/resoul/prism.git", from: "0.1.0"),
]
```

Or connect the umbrella library target `Prism` to your application target.

---

## Running Tests & Verifications

```bash
# Run package unit tests
swift test

# Run build verification script (macOS build, iOS simulator build check, selective import verification)
./scripts/check_build.sh
```
