# Your First Prism App

Prism supports iOS 16+, macOS 14+, and tvOS 17+. Import `PrismUI` for a UI-only app, or `Prism` when the app also uses Prism data and storage products. Public Prism APIs do not require UIKit, AppKit, SwiftUI, or Metal imports.

```swift
import PrismUI

struct Welcome: Component {
    func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 12) {
            Text("Welcome to Prism").font(.heading)
            Button("Continue") { }
        }
        .padding(24)
        .render(in: context)
    }
}
```

Mount `Welcome().render()` through the platform host supplied by your app target. Give dynamic rows explicit stable keys, keep app state in Flux or a screen binding, and keep per-component transient state scoped to its mounted identity.

## Consumer verification

From a fresh package consumer, run `swift build` after adding the package and compile the sample with only `import PrismUI`. The package release check independently proves that `PrismData` cannot leak through that import.
