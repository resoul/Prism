# Platform Host Views & Smoke Verification Guide

This guide explains how to embed Prism components in native iOS and macOS applications using thin host views, configure developer diagnostics, and run cross-platform verification scenarios.

---

## 1. Architectural Overview

Prism keeps its Component and Virtual Render Tree APIs 100% free of platform UI dependencies. Platform integration occurs exclusively through thin host bridge adapters:

```
┌────────────────────────────────────────┐
│  HostUIView (iOS) / HostNSView (macOS)  │ (Platform UI View)
└───────────────────┬────────────────────┘
                    │ bounds, safeArea, scale, appearance
                    ▼
┌────────────────────────────────────────┐
│  PrismHostEngine                       │ (@MainActor Lifecycle & Layout Driver)
└───────────┬────────────────┬───────────┘
            │                │
            ▼                ▼
┌──────────────────┐  ┌──────────────────┐
│ Layout Engine    │  │ CALayer Tree     │
│ (2-pass flex)    │  │ (ContainerLayer) │
└──────────────────┘  └──────────────────┘
```

---

## 2. Embedding Prism in iOS / macOS

### Universal Typealias: `PrismHostView`

`PrismUI` provides `PrismHostView`, which maps to `HostUIView` on iOS/tvOS and `HostNSView` on macOS.

### iOS Integration Example (`UIViewController`)

```swift
import UIKit
import PrismUI

class ViewController: UIViewController {
    private var hostView: HostUIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        let root = SmokeScene.makeRoot()
        let host = HostUIView(element: root)
        host.frame = view.bounds
        host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host)
        self.hostView = host
    }
}
```

### macOS Integration Example (`NSApplicationDelegate` / `NSViewController`)

```swift
import Cocoa
import PrismUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let root = SmokeScene.makeRoot()
        let host = HostNSView(element: root)
        host.frame = window.contentView?.bounds ?? CGRect(x: 0, y: 0, width: 600, height: 500)
        host.autoresizingMask = [.width, .height]
        window.contentView = host
    }
}
```

---

## 3. Developer Diagnostics & Wireframe Overlay

### Runtime Layout Wireframe Overlay

Toggle `isInspectorOverlayEnabled` on any host view to display semi-transparent bounding outlines around every laid-out node:

```swift
hostView.isInspectorOverlayEnabled = true // Enable layout wireframes
hostView.isInspectorOverlayEnabled = false // Disable overlay
```

### Textual Diagnostic Dump

Call `engine.dumpDiagnostics()` to inspect the complete state of the host:

```swift
print(hostView.engine.dumpDiagnostics())
```

Output includes:
- View bounds, scale factor, and color scheme
- Complete VRT element hierarchy (`dumpTree()`)
- Computed 2-pass layout trace with frames and constraints (`dumpTrace()`)
- Rendered CALayer hierarchy and total layer count

---

## 4. Launching Smoke Tests & Verification Commands

### Running Unit & Host Lifecycle Tests

```bash
cd /Users/resoul/projects/test-ui/Prism
swift test --filter PlatformHostTests
```

### Complete Cross-Platform Build & Isolation Verification

```bash
cd /Users/resoul/projects/test-ui/Prism
./scripts/check_build.sh
```

### Running macOS App Scheme

From the workspace:
```bash
xcodebuild -project /Users/resoul/projects/test-ui/macOS/macOS.xcodeproj \
  -scheme macOS \
  -destination 'platform=macOS' \
  build
```

### Running iOS Simulator Scheme

```bash
xcodebuild -project /Users/resoul/projects/test-ui/iOS/iOS.xcodeproj \
  -scheme iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  build
```
