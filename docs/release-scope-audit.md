# Release Scope and Evidence Audit

Status: audit completed on 2026-09-05 against `main` at `3c39a79` (Task 21 merge).

This audit compares the original Task 01–21 acceptance requirements with the implementation, tests, shipped documentation, and available platform evidence. “Implemented” means executable package evidence exists; “partial” means the contract exists but one or more required acceptance dimensions are missing; “unverified” means the required platform or performance run was not available. Merged work is not treated as proof of release readiness.

## Evidence matrix

| Task | Scope | Status | Evidence and gap |
| --- | --- | --- | --- |
| 01 | Package/module contracts | Implemented | `Package.swift`, selective-import checks, and package tests. |
| 01a | Logging, privacy, sinks | Implemented | Logging tests cover filtering, redaction, sinks, and rotation; crash/remote upload is intentionally out of scope. |
| 02 | Theme, tokens, typography | Partial | Unit coverage exists; required visual readability smoke on iOS/macOS is unverified. |
| 02a | Localization, Dynamic Type, RTL | Partial | Localization/scaling tests exist; golden LTR/RTL layouts and runtime smoke are unverified. |
| 03 | VRT/component API | Implemented | VRT and builder tests cover identity, value semantics, builders, and modifiers. |
| 04 | Layout foundation | Implemented | Layout, text measurement, and constraint/property tests pass. |
| 05 | Flex layout/positioning | Partial | Flex tests pass; golden matrix and macOS resize demo evidence are unverified. |
| 06 | CALayer renderer | Partial | Hierarchy/idempotency tests pass; snapshots and 100-render Instruments leak run are unverified. |
| 07 | iOS/macOS hosts | Unverified | Host code/tests exist, but launch/rotation/background/Retina smoke and 20-cycle evidence are absent. |
| 08 | Reconciler/Flux updates | Implemented | Reconciler, reactive, keyed-update, and cancellation tests pass. |
| 08a | State, Binding, effects | Implemented | Lifecycle tests cover persistence, binding loop prevention, and effect cancellation. |
| 09 | Events/focus/accessibility | Partial | Model tests pass; keyboard, VoiceOver, tvOS spatial, and stable lookup smoke are unverified. |
| 09a | Portal/OverlayHost | Partial | Portal tests cover routing/identity; clipped-scroll, anchor-after-scroll, and platform AX/focus evidence are unverified. |
| 10 | Icons/SVG | Partial | Parser/security/path tests pass; visual snapshots and non-main-thread file-load evidence are unverified. |
| 11 | Text editing/controls | Partial | Core editing/form unit tests pass; IME, paste, selection, keyboard, VoiceOver, and end-to-end flow are unverified. |
| 11a | Loadable/PagedStore | Implemented | State-machine, cancellation, deduplication, retry, and resource tests pass. |
| 12 | Scroll/LazyList/images | Partial | Physics, virtualization, image, and scheduler tests pass; 60/120 Hz traces and memory/frame evidence are unverified. |
| 12a | CollapsingTabPager | Partial | Coordinator, gesture, pagination, and 10k-item tests pass; platform gesture, AX, and Instruments evidence are unverified. |
| 13 | P1 catalog/demo | Partial | P1 tests/demo source exist; complete isolated interaction catalog and cross-platform AX audit are unverified. |
| 14 | Animation/transitions | Partial | Lifecycle/Reduce Motion tests pass; 60 Hz manual demo evidence is unverified. |
| 15 | Storage/cache/data | Implemented | Storage, cache, HTTP, WebSocket, and repository tests pass; Keychain-unavailable run is not separately evidenced. |
| 16 | Navigation/responsive/macOS | Partial | Router/restoration/responsive tests pass; multi-window and incoming-URL/rotation smoke are unverified. |
| 17 | Optional Metal | Partial | Shader/device/fallback tests pass; GPU/CPU/memory profile and 10-minute soak are unverified. |
| 18 | P2 display/layout | Partial | P2 tests and catalog metadata pass; snapshot matrix, AX inspection, and isolated examples are not fully evidenced. |
| 19 | P2 data entry | Partial | Numeric/range/select/form tests pass; keyboard/touch, AX actions, and reconcile focus audit are unverified. |
| 20 | P2 overlay/feedback/navigation | Partial | Lifecycle/stacking/navigation tests pass; 100-toast stress and platform AX/focus evidence are unverified. |
| 21 | Catalog/docs/0.x gate | Partial | Catalog tests/docs exist; catalog is metadata-driven rather than a complete interactive isolated catalog, and iOS build is fail-open. |

## Release blockers and reproducible scenarios

| Priority | Blocker / reproducer | Owner / follow-up |
| --- | --- | --- |
| P0 | Run `./scripts/check_build.sh`; make the iOS `xcodebuild` failure visible. The current script catches every failure and prints success. | 21b — Strict Platform Builds and CI |
| P0 | Build a fresh host from `docs/getting-started/first-app.md`, launch on iOS and macOS, rotate/resize, background/foreground, and inspect the rendered tree. No artifact is recorded. | 21f — Fresh Consumer and Release Sign-off |
| P1 | Open `PrismCatalogScreen` and activate every P0/P1/P2 entry; verify state controls, isolation, and stable test IDs. Current catalog enumerates metadata but does not prove each interaction. | 21c — Interactive Component Catalog |
| P1 | Execute iOS/macOS VoiceOver/keyboard for events, portals, P2 entry, and overlays; verify focus return after dismissal and AX actions. | 21d — Visual Regression and Accessibility Audit |
| P1 | Capture light/dark and scale snapshots, then run Instruments frame, GPU, memory, layer, and subscription soaks for scroll/pager/Metal. | 21d / 21e — Visual/AX and Performance Evidence |

P3 work must not be used to close these gaps. Each blocker requires its own reproducer, regression evidence where applicable, and branch/commit under AGENTS.md.

## Commands run

- `git status --short && git branch --show-current && git log --oneline -6` — clean `phase-05/task-21a-release-gate-audit`, based on `main` merge `3c39a79`.
- `swift test` — passed, 358 tests, 0 failures (2026-09-05).
- `./scripts/check_build.sh` — not accepted as release proof: its iOS `xcodebuild` step suppresses failures; macOS/package portions are covered by the passing test/build path.
- Manual iOS/iPadOS/macOS launch, AX, snapshot, and Instruments runs — not run in this environment; recorded as unverified.
