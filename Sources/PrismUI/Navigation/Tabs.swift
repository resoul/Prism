import Foundation
import CoreGraphics
import PrismCore

/// Declarative tabbed navigation interface linking tab selectors with corresponding content panels.
public struct Tabs<Tab: TabItem>: Component {
    public let tabs: [Tab]
    public let selection: Tab
    public let onSelect: @Sendable (Tab) -> Void
    public let panelBuilder: @Sendable (Tab) -> [RenderElement]

    public init(
        _ tabs: [Tab],
        selection: Tab,
        onSelect: @escaping @Sendable (Tab) -> Void,
        @ComponentBuilder panel: @escaping @Sendable (Tab) -> [RenderElement]
    ) {
        self.tabs = tabs
        self.selection = selection
        self.onSelect = onSelect
        self.panelBuilder = panel
    }

    public init(
        _ tabs: [Tab],
        selection: Binding<Tab>,
        @ComponentBuilder panel: @escaping @Sendable (Tab) -> [RenderElement]
    ) {
        let currentTab = selection.wrappedValue
        self.init(
            tabs,
            selection: currentTab,
            onSelect: { newTab in
                selection.wrappedValue = newTab
            },
            panel: panel
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        let surfaceColor = context.theme?.colors.secondary ?? Color.hex("#F1F5F9")

        // 1. Tab Selector Bar
        var tabButtons: [RenderElement] = []
        for tab in tabs {
            let isSelected = (tab == selection)
            let tabElementID = ElementID(typeName: "Tab", key: "\(tab.id)")

            var props = ElementProps(accessibilityLabel: tab.title)
            props.custom["role"] = "tab"
            props.custom["selected"] = isSelected ? "true" : "false"
            props.custom["controls"] = "panel_\(tab.id)"

            let titleElement = RenderElement(
                id: ElementID(typeName: "Text", key: "\(tab.id)_title"),
                kind: .text(tab.title)
            )

            var buttonModifiers: [ElementModifier] = [
                .padding(.init(top: 8, leading: 16, bottom: 8, trailing: 16)),
                .testID("tab_\(tab.id)")
            ]

            if isSelected {
                buttonModifiers.append(.background(surfaceColor))
            }

            let button = RenderElement(
                id: tabElementID,
                kind: .stack(axis: .horizontal, alignment: .center, spacing: 0),
                props: props,
                modifiers: buttonModifiers,
                children: [titleElement]
            )
            tabButtons.append(button)
        }

        let tabListID = ElementID(typeName: "TabList")
        var tabListProps = ElementProps()
        tabListProps.custom["role"] = "tablist"

        let tabList = RenderElement(
            id: tabListID,
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 4.0),
            props: tabListProps,
            modifiers: [.padding(.init(top: 4, leading: 4, bottom: 4, trailing: 4))],
            children: tabButtons
        )

        // 2. Active Tab Panel
        let activeContent = panelBuilder(selection)
        let panelID = ElementID(typeName: "TabPanel", key: "panel_\(selection.id)")
        var panelProps = ElementProps()
        panelProps.custom["role"] = "tabpanel"
        panelProps.custom["labelledBy"] = "tab_\(selection.id)"

        let panel = RenderElement(
            id: panelID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 0),
            props: panelProps,
            children: activeContent
        )

        // 3. Root Tabs Container
        let rootID = ElementID(typeName: "Tabs")
        return RenderElement(
            id: rootID,
            kind: .stack(axis: .vertical, alignment: .stretch, spacing: 8.0),
            children: [tabList, panel]
        )
    }
}
