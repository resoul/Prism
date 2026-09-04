import Foundation
import PrismCore

/// Runnable integration fixture for feedback, navigation, and overlay composition.
public struct P2OverlayFeedbackNavigationDemoScreen: Component {
    public init() {}
    public func body(context: ComponentContext) -> RenderElement {
        var page = 1; var selected = "home"; var presented = true
        let toast = ToastItem(title: "Network request complete", message: "Your changes were saved.", variant: .success)
        return VStack(alignment: .stretch, spacing: 16) {
            Text("P2 Overlay, Feedback, and Navigation").font(.heading)
            Toast(toast)
            Progress(value: 3, total: 4, label: "Uploading assets")
            Breadcrumb([BreadcrumbItem("Home", path: "/"), BreadcrumbItem("Settings")])
            Pagination(page: Binding(get: { page }, set: { page = $0 }), pageCount: 5)
            NavigationMenu(items: [NavigationMenuItem(id: "home", title: "Home"), NavigationMenuItem(id: "settings", title: "Settings")], selection: Binding(get: { selected }, set: { selected = $0 }))
            AlertDialog(isPresented: Binding(get: { presented }, set: { presented = $0 }), title: "Discard changes?", message: "This action cannot be undone.", onConfirm: {})
            Sheet(isPresented: Binding(get: { presented }, set: { presented = $0 }), title: "Details") { Text("Sheet content") }
            Drawer(isPresented: Binding(get: { presented }, set: { presented = $0 }), title: "Navigation") { Text("Drawer content") }
            Popover(isPresented: Binding(get: { presented }, set: { presented = $0 }), anchorID: "settings-trigger") { Text("Popover content") }
            DropdownMenu(isPresented: Binding(get: { presented }, set: { presented = $0 }), anchorID: "settings-trigger", items: [DropdownMenuItem(id: "delete", title: "Delete", isDestructive: true)])
            ContextMenu(isPresented: Binding(get: { presented }, set: { presented = $0 }), location: .zero, items: [DropdownMenuItem(id: "copy", title: "Copy")])
        }.padding(24).render(in: context)
    }
}
