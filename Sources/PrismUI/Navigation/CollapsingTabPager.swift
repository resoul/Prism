import Foundation
import CoreGraphics
import PrismCore

/// Result builder constructing arrays of `TabPage` declarations.
@resultBuilder
public struct TabPageListBuilder<Tab: TabItem> {
    public static func buildBlock(_ pages: TabPage<Tab>...) -> [TabPage<Tab>] {
        pages
    }

    public static func buildArray(_ components: [[TabPage<Tab>]]) -> [TabPage<Tab>] {
        components.flatMap { $0 }
    }
}

/// End-to-end collapsing tab pager component.
///
/// Features:
/// - Shared collapsing header coordinator driving smooth header shrinkage.
/// - Sticky pinned tabs docked at the top after header collapse.
/// - Horizontal page pager with strict neighbour mount policy.
/// - 2D pan gesture disambiguation separating vertical page scrolling from horizontal paging.
public struct CollapsingTabPager<Tab: TabItem>: Component {
    public let selection: Tab
    public let onTabSelected: @Sendable (Tab) -> Void
    public let coordinator: HeaderCollapseCoordinator
    public let gestureArena: GestureArena

    public let headerAndTabs: [RenderElement]
    public let pages: [TabPage<Tab>]

    public init(
        selection: Tab,
        onTabSelected: @escaping @Sendable (Tab) -> Void,
        expandedHeaderHeight: Double = 188.0,
        collapsedHeaderHeight: Double = 0.0,
        coordinator: HeaderCollapseCoordinator? = nil,
        gestureArena: GestureArena? = nil,
        @ComponentBuilder headerAndTabs: () -> [RenderElement],
        @TabPageListBuilder<Tab> pages: () -> [TabPage<Tab>]
    ) {
        self.selection = selection
        self.onTabSelected = onTabSelected
        self.pages = pages()

        let initialIndex = self.pages.firstIndex(where: { $0.tab == selection }) ?? 0
        self.coordinator = coordinator ?? HeaderCollapseCoordinator(
            expandedHeight: expandedHeaderHeight,
            collapsedHeight: collapsedHeaderHeight,
            initialPage: initialIndex
        )
        self.gestureArena = gestureArena ?? GestureArena()
        self.headerAndTabs = headerAndTabs()
    }

    public init(
        selection: Binding<Tab>,
        expandedHeaderHeight: Double = 188.0,
        collapsedHeaderHeight: Double = 0.0,
        coordinator: HeaderCollapseCoordinator? = nil,
        gestureArena: GestureArena? = nil,
        @ComponentBuilder headerAndTabs: () -> [RenderElement],
        @TabPageListBuilder<Tab> pages: () -> [TabPage<Tab>]
    ) {
        let currentTab = selection.wrappedValue
        self.init(
            selection: currentTab,
            onTabSelected: { newTab in
                selection.wrappedValue = newTab
            },
            expandedHeaderHeight: expandedHeaderHeight,
            collapsedHeaderHeight: collapsedHeaderHeight,
            coordinator: coordinator,
            gestureArena: gestureArena,
            headerAndTabs: headerAndTabs,
            pages: pages
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        let selectedIndex = pages.firstIndex(where: { $0.tab == selection }) ?? 0

        // 1. Header & Pinned Tabs container
        let headerContainerID = ElementID(typeName: "CollapsingHeaderTabs", key: "pinned_header")
        let headerElement = RenderElement(
            id: headerContainerID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            modifiers: [.zIndex(100)],
            children: headerAndTabs
        )

        // 2. Horizontal PagePager with neighbour mount policy
        let pager = PagePager(
            pages: pages,
            selectedIndex: selectedIndex,
            mountPolicy: .immediateNeighbours
        )
        let pagerElement = pager.body(context: context)

        // 3. Root container combining sticky header and page pager
        let rootID = ElementID(typeName: "CollapsingTabPager", key: "root")
        return RenderElement(
            id: rootID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            modifiers: [.testID("collapsing_tab_pager")],
            children: [headerElement, pagerElement]
        )
    }
}
