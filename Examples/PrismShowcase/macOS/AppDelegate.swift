import AppKit
import PrismUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = ShowcaseCounterStore()
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.arguments.contains("-showcaseReset") {
            store.reset()
        }

        let host = HostNSView(element: store.rootElement())
        host.setAccessibilityIdentifier("showcase.host")
        store.onChange = { [weak host] element in host?.setRootElement(element) }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Prism Showcase"
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
