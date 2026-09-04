# 0.x Release Checklist

See [Platform Build Verification](platform-build-verification.md) for the
strict local and CI build gate.

- [ ] `swift test` and `./scripts/check_build.sh` pass from a clean checkout.
- [ ] Build iOS, iPadOS, macOS, and tvOS targets; record unavailable environments rather than treating them as passed.
- [ ] Run `CatalogReleaseTests`, component snapshots, accessibility screen, and fresh-consumer `import PrismUI` compile check.
- [ ] Manually validate keyboard tab/Escape/Return, focus restoration, high contrast, Reduce Motion, text input/IME, long press/right click, and compact/desktop overlay placement.
- [ ] Capture the performance baseline procedure in `docs/performance/release-baseline.md` and check layer/subscription leaks.
- [ ] Review `docs/known-limitations.md`, CHANGELOG, platform matrix, README examples, licence/attribution, and dependency versions.

## Pre-1.0 compatibility policy

Prism follows SemVer, but `0.x` minor releases may make breaking public API changes. Such changes require an ADR, migration note, changelog entry, and a fresh-consumer compile example. Patch releases do not intentionally break public source compatibility.
