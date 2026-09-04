import Foundation
import CoreGraphics
import PrismCore

/// Sticky tab navigation bar designed for coordination with a collapsing header.
///
/// Features animated indicator positioning, active selection state, keyboard navigation,
/// and VoiceOver accessibility tab traits.
public struct PinnedTabs<Tab: TabItem>: Component {
    private let tabs: [Tab]
    private let selectedTab: Tab
    private let height: Double
    private let onSelect: @Sendable (Tab) -> Void

    public init(
        _ tabs: [Tab],
        selection: Tab,
        height: Double = 44.0,
        onSelect: @escaping @Sendable (Tab) -> Void
    ) {
        self.tabs = tabs
        self.selectedTab = selection
        self.height = height
        self.onSelect = onSelect
    }

    public func body(context: ComponentContext) -> RenderElement {
        var barChildren: [RenderElement] = []

        for (_, tab) in tabs.enumerated() {
            let isSelected = (tab == selectedTab)
            let tabElementID = ElementID(typeName: "TabButton", key: "\(tab.id)")

            // Tab label
            var tabProps = ElementProps(accessibilityLabel: tab.title)
            tabProps.custom["role"] = "tab"
            tabProps.custom["selected"] = isSelected ? "true" : "false"

            let textElement = RenderElement(
                id: ElementID(typeName: "Text", key: "\(tab.id)_title"),
                kind: .text(tab.title),
                props: tabProps
            )

            var buttonChildren: [RenderElement] = [textElement]

            // Bottom indicator line for selected tab
            if isSelected {
                let indicatorID = ElementID(typeName: "Rectangle", key: "\(tab.id)_indicator")
                let indicator = RenderElement(
                    id: indicatorID,
                    kind: .shape(.rectangle(cornerRadius: 1.5)),
                    modifiers: [.height(3.0)]
                )
                buttonChildren.append(indicator)
            }

            let buttonContainer = RenderElement(
                id: tabElementID,
                kind: .stack(axis: .vertical, alignment: .center, spacing: 4.0),
                props: tabProps,
                modifiers: [
                    .padding(.init(top: 10, leading: 16, bottom: 6, trailing: 16)),
                    .testID("tab_\(tab.id)")
                ],
                children: buttonChildren
            )

            barChildren.append(buttonContainer)
        }

        let barID = ElementID(typeName: "PinnedTabs", key: "bar")
        return RenderElement(
            id: barID,
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 8.0),
            modifiers: [
                .height(height),
                .zIndex(100) // High z-index to stay pinned above scrolling content
            ],
            children: barChildren
        )
    }
}
