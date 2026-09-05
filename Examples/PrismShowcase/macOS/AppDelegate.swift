import AppKit
import PrismUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ShowcaseCounterStore()
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the application is treated as a standard foreground GUI app
        NSApp.setActivationPolicy(.regular)

        if ProcessInfo.processInfo.arguments.contains("-showcaseReset") {
            store.reset()
        }

        setupMainMenu()

        let host = HostNSView(element: store.rootElement(), theme: store.activeTheme)
        host.setAccessibilityIdentifier("showcase.host")
        store.setContainerWidth(900)
        host.onBoundsChange = { [weak store] bounds in
            store?.setContainerWidth(bounds.width)
        }
        store.onChange = { [weak host] element in host?.setRootElement(element) }
        store.onThemeChange = { [weak host] theme in host?.setTheme(theme) }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Prism Showcase"
        window.minSize = NSSize(width: 480, height: 400)
        window.contentView = host
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // Application Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Prism Showcase", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Prism Showcase", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Prism Showcase", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // Window Menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
