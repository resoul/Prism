# Interactive showcase readiness

Baseline: `main` `0242313` (Task 22w merge), audited 2026-09-05.

The package has a strong renderer, event, focus, theme, model, and render-tree
foundation. It is ready to start the showcase work, but it is not yet evidence
that a complete iOS/macOS component application exists.

## Current state

- `Examples/FreshConsumer` is a compile and render-tree smoke fixture. It prints
  a tree and is not an iOS or macOS application.
- `PrismCatalogHost` exposes tier filters and state metadata. Its detail switch
  has ten explicit component cases; the remaining entries use a generic Card
  fallback, and P3 entries are absent.
- Native hosts already expose mounting, pointer, key, scroll, focus, and internal
  accessibility hooks. No native iOS/macOS launch and UI evidence is checked in.
- Theme resolution supports named IDs and system mapping. A live five-preset
  showcase with mounted theme switching does not yet exist.
- Release documents record package and deterministic model tests. Native AX,
  pixel snapshots, Instruments traces, and platform launch evidence remain
  unverified.

## Decision

Phase 07 may begin with the evidence inventory and native host work. The old
release/P3 requirements are archived for traceability; their merge history is
not a substitute for the evidence listed above. CI remains intentionally
disabled until the owner requests its restoration.

## Exit condition

Readiness is complete only when the registry has no unexplained fallback,
Welcome → Categories → Component Detail works in both apps, the five themes
change real rendered pixels, and `23ab` records native interaction, AX,
snapshot, and performance results with exact commands and environments.
