#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONSUMER_DIR="$PACKAGE_DIR/Examples/FreshConsumer"

echo "==> Building pinned fresh consumer..."
swift build --package-path "$CONSUMER_DIR" --configuration release
echo "==> Running pinned fresh consumer..."
swift run --package-path "$CONSUMER_DIR" --configuration release

if rg -n '^import (UIKit|AppKit|SwiftUI)' "$CONSUMER_DIR/Sources"; then
    echo "ERROR: consumer UI source imports a platform UI framework." >&2
    exit 1
fi
echo "✔ Fresh consumer built and uses only PrismUI/Flux imports."
