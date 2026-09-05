#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_dir="$(cd "$script_dir/.." && pwd)"
project="$package_dir/Examples/PrismShowcase/PrismShowcase.xcodeproj"
derived_data="${PRISM_SHOWCASE_DERIVED_DATA:-$package_dir/.build/showcase-derived-data}"

if [[ ! -d "$project" ]]; then
    echo "Missing showcase project: $project" >&2
    exit 1
fi

echo "==> Building and testing PrismShowcase-macOS"
mac_arch="$(uname -m)"
xcodebuild -project "$project" -scheme PrismShowcase-macOS \
    -destination "platform=macOS,arch=$mac_arch" ARCHS="$mac_arch" ONLY_ACTIVE_ARCH=YES \
    -derivedDataPath "$derived_data" test

echo "==> Building PrismShowcase-macOS UI-test bundle"
xcodebuild -project "$project" -scheme PrismShowcase-macOS \
    -destination "platform=macOS,arch=$mac_arch" ARCHS="$mac_arch" ONLY_ACTIVE_ARCH=YES \
    -derivedDataPath "$derived_data" build-for-testing

ios_destination="${PRISM_IOS_DESTINATION:-}"
if [[ -z "$ios_destination" ]]; then
    simulator_id="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
    if [[ -z "$simulator_id" ]]; then
        echo "BLOCKED: no available iPhone simulator. Install a runtime or set PRISM_IOS_DESTINATION." >&2
        exit 2
    fi
    ios_destination="platform=iOS Simulator,id=$simulator_id"
fi

echo "==> Building PrismShowcase-iOS and its UI-test bundle ($ios_destination)"
ios_arch="$(uname -m)"
xcodebuild -project "$project" -scheme PrismShowcase-iOS \
    -destination "$ios_destination" ARCHS="$ios_arch" ONLY_ACTIVE_ARCH=YES \
    -derivedDataPath "$derived_data" build-for-testing
