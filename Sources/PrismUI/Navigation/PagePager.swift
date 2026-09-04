import Foundation
import CoreGraphics
import PrismCore

/// Horizontal page pager rendering tab pages with a strict neighbour-only mount policy.
///
/// Only the active page and its immediate left/right adjacent pages are instantiated
/// and mounted in the render tree. Distant pages are unmounted to conserve memory
/// and prevent background CALayer and subscription leaks.
public struct PagePager<Tab: TabItem>: Component {
    public let pages: [TabPage<Tab>]
    public let selectedIndex: Int
    public let mountPolicy: NeighbourMountPolicy

    public init(
        pages: [TabPage<Tab>],
        selectedIndex: Int,
        mountPolicy: NeighbourMountPolicy = .immediateNeighbours
    ) {
        self.pages = pages
        self.selectedIndex = selectedIndex
        self.mountPolicy = mountPolicy
    }

    public func body(context: ComponentContext) -> RenderElement {
        let activeIndices = mountPolicy.activeIndices(selected: selectedIndex, total: pages.count)

        var mountedPageElements: [RenderElement] = []

        for (index, page) in pages.enumerated() {
            guard activeIndices.contains(index) else {
                // Distant pages are unmounted completely
                continue
            }

            let pageContent = page.contentProvider()
            let pageID = ElementID(typeName: "TabPageView", key: "\(page.tab.id)")

            let pageContainer = RenderElement(
                id: pageID,
                kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
                modifiers: [.testID("page_\(page.tab.id)")],
                children: pageContent
            )
            mountedPageElements.append(pageContainer)
        }

        let pagerID = ElementID(typeName: "PagePager", key: "container")
        return RenderElement(
            id: pagerID,
            kind: .stack(axis: .horizontal, alignment: .stretch, spacing: 0),
            children: mountedPageElements
        )
    }
}
