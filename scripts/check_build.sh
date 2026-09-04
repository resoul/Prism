#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_PATH="${PRISM_BUILD_PATH:-$PACKAGE_DIR/.build}"

echo "==> [1/6] Running Swift package tests..."
swift test --package-path "$PACKAGE_DIR" --build-path "$BUILD_PATH"

echo "==> [2/6] Verifying package manifest and macOS release build..."
swift package --package-path "$PACKAGE_DIR" describe --type json >/dev/null
swift build --package-path "$PACKAGE_DIR" --configuration release --build-path "$BUILD_PATH"
echo "    ✔ SwiftPM manifest is the authoritative build definition (no Xcode project/scheme required)."

require_sdk() {
    local sdk="$1"
    if ! xcrun --sdk "$sdk" --show-sdk-path >/dev/null 2>&1; then
        echo "BLOCKED: required SDK '$sdk' is unavailable on this host." >&2
        exit 2
    fi
    echo "    ✔ SDK available: $sdk ($(xcrun --sdk "$sdk" --show-sdk-path))"
}

build_triple() {
    local label="$1"; local sdk="$2"; local triple="$3"; local step="$4"
    echo "==> [$step/6] Verifying $label compile ($triple)..."
    require_sdk "$sdk"
    local sdk_path
    sdk_path="$(xcrun --sdk "$sdk" --show-sdk-path)"
    swift build --package-path "$PACKAGE_DIR" --configuration release \
        --triple "$triple" --sdk "$sdk_path" --build-path "$BUILD_PATH/$label"
}

build_triple "iOS Simulator" iphonesimulator arm64-apple-ios16.0-simulator 3
build_triple "tvOS Simulator" appletvsimulator arm64-apple-tvos17.0-simulator 4

echo "==> [5/6] Verifying positive umbrella compile control..."
MODULES_DIR="$BUILD_PATH/arm64-apple-macosx/debug/Modules"

# 1. Umbrella import check: 'import Prism' provides full SDK without UIKit/AppKit
swiftc -typecheck -I "$MODULES_DIR" -e '
import Prism

@MainActor
func verifyUmbrella() {
    let id = ElementID(typeName: "Stack", key: "main", siblingIndex: 0)
    _ = id.description
    _ = PrismUI.layerDescription
    _ = PrismData.layerDescription
    _ = PrismStorage.layerDescription
    _ = PrismLogging.subsystem
}
'
echo "    ✔ Umbrella 'import Prism' compile control passed."

# 2. Selective import check: 'import PrismUI' provides PrismCore, but isolates PrismData & PrismStorage
if swiftc -typecheck -I "$MODULES_DIR" -e '
import PrismUI

@MainActor
func verifyIsolation() {
    let id = ElementID(typeName: "Text", key: nil, siblingIndex: 0)
    _ = id.description
    _ = PrismData.layerDescription
}
' >/dev/null 2>&1; then
    echo "ERROR: PrismData should NOT be visible when importing only PrismUI!"
    exit 1
else
    echo "    ✔ PrismUI import isolation passed."
fi

echo "==> Verifying fail-fast behavior for an invalid product..."
if swift build --package-path "$PACKAGE_DIR" --product __PrismMissingProduct --build-path "$BUILD_PATH/invalid" >/dev/null 2>&1; then
    echo "ERROR: invalid product unexpectedly succeeded." >&2
    exit 1
fi
echo "    ✔ Invalid product returns nonzero as expected."
echo "==> All strict Prism build and contract checks passed."
