# Fresh Consumer Release Sign-off

The checked-in [`Examples/FreshConsumer`](../Examples/FreshConsumer) fixture is
a minimal app using only `PrismUI` and `Flux`. Its manifest pins Prism to the
current release-gate revision and Flux to the resolved 1.1.0 revision; the
consumer source contains no UIKit, AppKit, or SwiftUI import.

Run:

```sh
./scripts/check_fresh_consumer.sh
```

The proposed first compatible release is `0.1.0` under the existing MIT
license. Until 1.0, minor releases may change source APIs only with an ADR,
migration note, changelog entry, and a refreshed consumer fixture; patch
releases remain source-compatible. Tagging, pushing a tag, and publishing are
separate owner-approved actions.

## Sign-off evidence

On 2026-09-05 the fixture resolved the pinned Prism/Flux revisions, built in
release configuration, ran the sample tree, and passed the no-platform-import
check on macOS 26.4.1 arm64. iOS/iPadOS/macOS native launch and UI automation
remain host-level checks from the release audit and are not claimed here.
