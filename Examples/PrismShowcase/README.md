# Prism Showcase

This Xcode project contains real iOS/iPadOS and macOS host applications for
interactive Prism examples. The shared screen uses `PrismUI`; UIKit and AppKit
only create the application/window and mount `HostUIView` or `HostNSView`.

Open `PrismShowcase.xcodeproj`, select either `PrismShowcase-iOS` or
`PrismShowcase-macOS`, and Run. Both schemes accept `-showcaseReset` to start
from deterministic example state.

Run the repeatable check from the package root:

```sh
./scripts/check_examples.sh
```

It runs the shared macOS logic tests (automation IDs, Flux state transitions, teardown cancellation, repeated leak-free mount cycles, and accessibility element bridging), then uses `build-for-testing` to build both app and UI-test bundles for macOS and an installed iOS simulator.
Set `PRISM_IOS_DESTINATION` to override its destination, for example
`platform=iOS Simulator,id=<UDID>`. Simulator builds are signing-free; use your
own Apple development team only when deploying to a physical device.

The showcase proves host redraw via Flux state transitions, touch panning/wheel scrolling, pointer capture/cancellation, text input focus and safe area adjustments, and native accessibility element bridging for labels and actions.

It also includes five bundled theme presets (`Light`, `Dark`, `Midnight`, `Forest`, and `Sand`) configured through `ShowcaseConfig.bundled`. Theme selection can be changed live via UI controls and persists via `ShowcasePreferences`, resetting back to system appearance with `-showcaseReset`. See [Extending.md](../../docs/examples/Extending.md) for declaring additional custom themes.
