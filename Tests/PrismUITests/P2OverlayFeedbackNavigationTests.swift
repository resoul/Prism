import XCTest
import QuartzCore
@testable import PrismCore
@testable import PrismUI

@MainActor
final class P2OverlayFeedbackNavigationTests: XCTestCase {
    func testToastQueueDeduplicatesAndPromotes() {
        let center = ToastCenter(maximumVisible: 2)
        let first = ToastItem(title: "Saved", deduplicationKey: "save")
        center.enqueue(first)
        center.enqueue(ToastItem(title: "Saved again", deduplicationKey: "save"))
        center.enqueue(ToastItem(title: "Synced"))
        center.enqueue(ToastItem(title: "Queued"))
        XCTAssertEqual(center.visible.count, 2)
        XCTAssertEqual(center.pending.count, 1)
        center.dismiss(id: first.id)
        XCTAssertEqual(center.visible.count, 2)
        XCTAssertEqual(center.pending.count, 0)
        XCTAssertEqual(center.lastAnnouncement, "Queued")
    }

    func testProgressAndNavigationSemantics() {
        let progress = Progress(value: 7, total: 10, label: "Upload")
        XCTAssertEqual(progress.fractionCompleted, 0.7)
        XCTAssertEqual(progress.render().props.custom["role"], "progressbar")
        XCTAssertEqual(Progress().render().props.custom["isIndeterminate"], "true")

        var page = 1
        let pagination = Pagination(page: Binding(get: { page }, set: { page = $0 }), pageCount: 3)
        pagination.previous(); XCTAssertEqual(page, 1)
        pagination.go(to: 5); XCTAssertEqual(page, 3)
    }

    func testNavigationMenuAndBreadcrumbDriveExistingNavigator() {
        let navigator = Navigator(initialPath: "/")
        var selection = "home"
        let menuItem = NavigationMenuItem(id: "profile", title: "Profile", path: "/profile")
        let menu = NavigationMenu(items: [menuItem], selection: Binding(get: { selection }, set: { selection = $0 }), navigator: navigator)
        menu.activate(menuItem)
        XCTAssertEqual(selection, "profile")
        XCTAssertEqual(navigator.currentEntry?.path, "/profile")

        let crumb = BreadcrumbItem("Settings", path: "/settings")
        Breadcrumb([crumb], navigator: navigator).activate(crumb)
        XCTAssertEqual(navigator.currentEntry?.path, "/settings")
    }

    func testOverlayComponentsEmitCorrectTierAndRole() {
        var shown = true
        let binding = Binding(get: { shown }, set: { shown = $0 })
        let sheet = Sheet(isPresented: binding, title: "Details") { Text("Body") }.render()
        XCTAssertEqual(sheet.kind, .portal(targetLayer: .modal))
        XCTAssertEqual(sheet.children.first?.props.custom["role"], "dialog")

        let popover = Popover(isPresented: binding, anchorID: "trigger") { Text("Menu") }.render()
        XCTAssertEqual(popover.kind, .portal(targetLayer: .floating))
        XCTAssertEqual(popover.children.first?.props.custom["placement"], "anchor:trigger")

        let menu = DropdownMenu(isPresented: binding, anchorID: "trigger", items: [DropdownMenuItem(id: "delete", title: "Delete", isDestructive: true)]).render()
        XCTAssertEqual(menu.children.first?.props.custom["role"], "menu")
    }

    func testOverlayHostReplacesExistingModal() {
        let root = RenderElement(id: ElementID(typeName: "Root"), kind: .empty).frame(width: 100, height: 100)
        let engine = PrismHostEngine(rootElement: root)
        let host = CALayer(); host.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        engine.bounds = host.bounds; engine.mount(in: host)

        let first = MountedNode(element: RenderElement(id: ElementID(typeName: "First"), kind: .empty))
        first.mount(superlayer: engine.overlayHost.modalContainer, overlayHost: engine.overlayHost)
        let second = MountedNode(element: RenderElement(id: ElementID(typeName: "Second"), kind: .empty))
        second.mount(superlayer: engine.overlayHost.modalContainer, overlayHost: engine.overlayHost)
        engine.overlayHost.present(OverlayEntry(id: first.id, layer: .modal, node: first))
        engine.overlayHost.present(OverlayEntry(id: second.id, layer: .modal, node: second))
        XCTAssertEqual(engine.overlayHost.activeEntries.count, 1)
        XCTAssertNotNil(engine.overlayHost.activeEntries[second.id])
    }

    func testIntegrationCatalogFixtureBuildsFeedbackNavigationAndOverlays() {
        XCTAssertGreaterThanOrEqual(P2OverlayFeedbackNavigationDemoScreen().render().children.count, 12)
    }
}
