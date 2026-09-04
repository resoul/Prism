import Foundation
@_exported import PrismCore

/// A disclosure component presenting a collapsible section of content beneath an interactive header.
public struct Collapsible: Component {
    public let title: String
    public let isExpanded: Binding<Bool>
    public let content: [RenderElement]

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.content = content()
    }

    /// Convenience initializer using an immutable boolean state and toggle callback.
    public init(
        title: String,
        isExpanded: Bool,
        onToggle: (@Sendable () -> Void)? = nil,
        @ComponentBuilder content: () -> [RenderElement]
    ) {
        self.init(
            title: title,
            isExpanded: Binding(
                get: { isExpanded },
                set: { _ in onToggle?() }
            ),
            content: content
        )
    }

    public func body(context: ComponentContext) -> RenderElement {
        let colors = context.theme?.colors ?? ThemeColors.defaultLight
        let expanded = isExpanded.wrappedValue

        return VStack(alignment: .stretch, spacing: 0) {
            // Header Toggle Row
            HStack(alignment: .center) {
                Text(title)
                    .font(.heading)
                    .foregroundColor(colors.foreground)

                Spacer()

                Icon(expanded ? "chevron.up" : "chevron.down")
                    .frame(width: 16, height: 16)
            }
            .padding(DirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .accessibilityElement(
                label: "\(title), \(expanded ? "expanded" : "collapsed")",
                role: "button"
            )

            // Disclosed Content
            if expanded {
                VStack(alignment: .stretch, spacing: 0) {
                    Divider()

                    VStack(alignment: .start, spacing: 8) {
                        for child in content {
                            child
                        }
                    }
                    .padding(DirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
                }
                .transition(.opacity)
            }
        }
        .background(colors.background)
        .sdfRoundedRect(
            cornerRadius: 8,
            borderWidth: 1,
            borderColor: colors.border,
            fill: colors.background
        )
        .render(in: context)
    }
}

/// Selection mode for an `Accordion`.
public enum AccordionMode: Sendable, Equatable {
    case single
    case multiple
}

/// Single item within a multi-section `Accordion`.
public struct AccordionItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let content: @Sendable () -> [RenderElement]

    public init(
        id: String = UUID().uuidString,
        title: String,
        @ComponentBuilder content: @escaping @Sendable () -> [RenderElement]
    ) {
        self.id = id
        self.title = title
        self.content = content
    }
}

/// Multi-section accordion coordinator managing mutually exclusive or multiple collapsible disclosures.
public struct Accordion: Component {
    public let items: [AccordionItem]
    public let mode: AccordionMode
    public let expandedIDs: Binding<Set<String>>

    public init(
        items: [AccordionItem],
        mode: AccordionMode = .single,
        expandedIDs: Binding<Set<String>>
    ) {
        self.items = items
        self.mode = mode
        self.expandedIDs = expandedIDs
    }

    public func body(context: ComponentContext) -> RenderElement {
        let currentSet = expandedIDs.wrappedValue

        return VStack(alignment: .stretch, spacing: 8) {
            for item in items {
                let isItemExpanded = currentSet.contains(item.id)

                Collapsible(
                    title: item.title,
                    isExpanded: Binding(
                        get: { isItemExpanded },
                        set: { expand in
                            var updated = currentSet
                            if expand {
                                if mode == .single {
                                    updated = [item.id]
                                } else {
                                    updated.insert(item.id)
                                }
                            } else {
                                updated.remove(item.id)
                            }
                            expandedIDs.wrappedValue = updated
                        }
                    ),
                    content: item.content
                )
            }
        }
        .accessibilityElement(label: "Accordion with \(items.count) sections", role: "list")
        .render(in: context)
    }
}
