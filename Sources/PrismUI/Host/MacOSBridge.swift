import Foundation
import CoreGraphics
@_exported import PrismCore

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// Standard toolbar item placement categories.
public enum ToolbarPlacement: Sendable, Equatable {
    case leading
    case principal
    case trailing
}

/// Pure declarative model for a window toolbar item.
public struct ToolbarItem: Sendable, Identifiable {
    public let id: String
    public let placement: ToolbarPlacement
    public let label: String
    public let iconName: String?
    public let isEnabled: Bool
    public let action: @Sendable () -> Void

    public init(
        id: String = UUID().uuidString,
        placement: ToolbarPlacement = .trailing,
        label: String,
        iconName: String? = nil,
        isEnabled: Bool = true,
        action: @escaping @Sendable () -> Void
    ) {
        self.id = id
        self.placement = placement
        self.label = label
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.action = action
    }
}

/// Standard application and edit menu commands.
public enum MenuCommand: Sendable, Equatable {
    case undo
    case redo
    case cut
    case copy
    case paste
    case selectAll
    case find
    case newWindow
    case closeWindow
    case custom(title: String, keyEquivalent: String, action: @Sendable () -> Void)

    public static func == (lhs: MenuCommand, rhs: MenuCommand) -> Bool {
        switch (lhs, rhs) {
        case (.undo, .undo): return true
        case (.redo, .redo): return true
        case (.cut, .cut): return true
        case (.copy, .copy): return true
        case (.paste, .paste): return true
        case (.selectAll, .selectAll): return true
        case (.find, .find): return true
        case (.newWindow, .newWindow): return true
        case (.closeWindow, .closeWindow): return true
        case (.custom(let t1, let k1, _), .custom(let t2, let k2, _)):
            return t1 == t2 && k1 == k2
        default: return false
        }
    }
}

/// Declaration of a multi-window capability for macOS desktop applications.
public struct WindowGroup: Sendable {
    public let id: String
    public var title: String
    public var defaultSize: CGSize
    public var minSize: CGSize
    public var isRestorable: Bool
    public let content: @Sendable (String?) -> any ComponentConvertible

    public init(
        id: String,
        title: String = "Prism Window",
        defaultSize: CGSize = CGSize(width: 900, height: 600),
        minSize: CGSize = CGSize(width: 400, height: 300),
        isRestorable: Bool = true,
        @ComponentBuilder content: @escaping @Sendable (String?) -> [RenderElement]
    ) {
        self.id = id
        self.title = title
        self.defaultSize = defaultSize
        self.minSize = minSize
        self.isRestorable = isRestorable
        self.content = content
    }

    public init(
        id: String,
        title: String = "Prism Window",
        defaultSize: CGSize = CGSize(width: 900, height: 600),
        minSize: CGSize = CGSize(width: 400, height: 300),
        isRestorable: Bool = true,
        content: @escaping @Sendable (String?) -> any ComponentConvertible
    ) {
        self.id = id
        self.title = title
        self.defaultSize = defaultSize
        self.minSize = minSize
        self.isRestorable = isRestorable
        self.content = content
    }
}

/// Thread-safe window and desktop integration manager without public AppKit exposure.
public final class WindowManager: @unchecked Sendable {
    public static let shared = WindowManager()

    private let lock = NSLock()
    private var registeredGroups: [String: WindowGroup] = [:]
    private var activeWindows: [String: Any] = [:]

    public init() {}

    /// Registers a WindowGroup available for multi-window opening.
    public func register(_ group: WindowGroup) {
        lock.withLock {
            registeredGroups[group.id] = group
        }
    }

    /// Programmatically opens a new window registered with the specified group ID.
    @MainActor
    public func openWindow(id: String, value: String? = nil) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        let group = lock.withLock { registeredGroups[id] }
        guard let group else { return }

        let elements = group.content(value).asRenderElements(in: ComponentContext())
        let rootElement = elements.count == 1 ? elements[0] : RenderElement(id: ElementID(typeName: "WindowRoot"), kind: .group, children: elements)
        let hostView = HostNSView(element: rootElement)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: group.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = group.title
        window.minSize = group.minSize
        window.contentView = hostView
        window.center()
        window.makeKeyAndOrderFront(nil)

        lock.withLock {
            activeWindows[UUID().uuidString] = window
        }
        #endif
    }

    /// Toggles the full-screen mode of the primary active window.
    @MainActor
    public func toggleFullScreen() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSApp.keyWindow?.toggleFullScreen(nil)
        #endif
    }

    /// Checks if a window group ID has been registered.
    public func hasGroup(_ id: String) -> Bool {
        lock.withLock { registeredGroups[id] != nil }
    }
}
