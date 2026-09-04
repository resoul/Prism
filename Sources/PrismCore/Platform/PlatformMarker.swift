import Foundation

// MARK: - Platform Bridge Foundation
// Invariant: Platform UI types (UIView, NSView, UIWindow, NSWindow) are strictly confined to
// Platform/ bridge implementation and renderer internals. They are never exposed in public APIs.

public enum PlatformBridgeMarker {
    public static let layerDescription = "Platform host adapters for iOS, macOS, tvOS"
}
