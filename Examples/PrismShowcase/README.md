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

It runs the shared macOS logic test, then uses `build-for-testing` to build both app and UI-test bundles for macOS and an installed iOS simulator. Native UI automation is added in Task 23c.
Set `PRISM_IOS_DESTINATION` to override its destination, for example
`platform=iOS Simulator,id=<UDID>`. Simulator builds are signing-free; use your
own Apple development team only when deploying to a physical device.

The initial UI test only proves both apps launch. Native Prism interaction and
accessibility assertions are deliberately added by Task 23c.
