# Platform Build Verification

`Prism` is a Swift Package and has no checked-in Xcode project or scheme. The
authoritative gate is `scripts/check_build.sh`, which fails on any command
error and uses the SDK selected by `xcrun` for each platform target.

The gate performs:

- all package tests and a macOS release build;
- iOS Simulator compile with `arm64-apple-ios16.0-simulator` and the
  `iphonesimulator` SDK;
- tvOS Simulator compile with `arm64-apple-tvos17.0-simulator` and the
  `appletvsimulator` SDK;
- positive `import Prism` and negative `PrismUI` isolation compile controls;
- an intentionally invalid product build, which must return nonzero.

On hosts without a required SDK the command exits with status 2 and reports
the check as `BLOCKED`; it never converts that result into a pass. CI runs the
same script on a macOS runner.

## Local command

```sh
./scripts/check_build.sh
```

On 2026-09-05, package tests passed (358 tests, 0 failures), macOS release,
iOS Simulator, and tvOS Simulator compiles passed, and the import/fail-fast
controls passed. tvOS emitted only the existing
`traitCollectionDidChange` deprecation warning.
