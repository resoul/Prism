import Foundation
import PrismCore

/// Component maturity tiers represented in the runnable Prism catalog.
public enum CatalogTier: String, CaseIterable, Sendable { case p0, p1, p2 }

/// One isolated catalog example and its supported state matrix.
public struct CatalogEntry: Identifiable, Sendable, Hashable {
    public let id: String
    public let component: String
    public let tier: CatalogTier
    public let category: String
    public let states: [String]
    public let documentationPath: String
    public init(_ component: String, tier: CatalogTier, category: String, states: [String], documentationPath: String) {
        self.id = component.lowercased(); self.component = component; self.tier = tier; self.category = category; self.states = states; self.documentationPath = documentationPath
    }
}

/// Canonical P0/P1/P2 catalog index. Each entry is an independently selectable example.
public enum PrismCatalog {
    public static let entries: [CatalogEntry] = {
        let basic = ["Text", "Stack", "HStack", "VStack", "Spacer", "Rectangle", "Circle", "Icon"].map { CatalogEntry($0, tier: .p0, category: "Primitives", states: ["default", "theme", "large type"], documentationPath: "docs/getting-started/component-api-vrt-guide.md") }
        let p1Display = ["Badge", "Label", "Avatar", "Card", "IconTile", "Image", "LazyList", "LazyGrid"].map { CatalogEntry($0, tier: .p1, category: "Data display", states: ["default", "loading", "empty", "dark"], documentationPath: "docs/guides/p1-component-catalog-guide.md") }
        let p1Entry = ["Button", "Input", "Textarea", "Checkbox", "RadioGroup", "Switch", "Toggle", "Field", "Form"].map { CatalogEntry($0, tier: .p1, category: "Data entry", states: ["default", "disabled", "error", "focused"], documentationPath: "docs/guides/text-editing-and-forms-guide.md") }
        let p1Other = ["Alert", "Spinner", "Tabs", "Dialog", "Tooltip", "Divider", "Frame", "ScrollArea"].map { CatalogEntry($0, tier: .p1, category: "Feedback, navigation, overlay, layout", states: ["default", "reduce motion", "high contrast"], documentationPath: "docs/guides/p1-component-catalog-guide.md") }
        let p2Display = ["CodeBlock", "Kbd", "Skeleton", "Empty", "HoverCard", "Table", "Timeline", "Accordion", "Collapsible", "AspectRatio"].map { CatalogEntry($0, tier: .p2, category: "Data display and layout", states: ["default", "open", "disabled", "dark"], documentationPath: "docs/guides/p2-components-guide.md") }
        let p2Entry = ["ButtonGroup", "NumberField", "ToggleGroup", "Slider", "RangeSlider", "Stepper", "Rating", "InputGroup", "Select", "NativeSelect"].map { CatalogEntry($0, tier: .p2, category: "Data entry", states: ["default", "disabled", "range boundary", "keyboard"], documentationPath: "docs/guides/p2-components-guide.md") }
        let p2Other = ["Toast", "Progress", "Breadcrumb", "Pagination", "NavigationMenu", "AlertDialog", "Sheet", "Drawer", "Popover", "DropdownMenu", "ContextMenu"].map { CatalogEntry($0, tier: .p2, category: "Feedback, navigation, overlay", states: ["default", "presented", "dismissed", "accessibility"], documentationPath: "docs/guides/p2-overlay-feedback-navigation-guide.md") }
        return basic + p1Display + p1Entry + p1Other + p2Display + p2Entry + p2Other
    }()

    public static func entries(tier: CatalogTier) -> [CatalogEntry] { entries.filter { $0.tier == tier } }
}

/// Catalog root with theme/size/interaction controls represented as stable, inspectable state.
public struct PrismCatalogScreen: Component {
    public var tier: CatalogTier?
    public var contentSize: ContentSizeCategory
    public var reduceMotion: Bool
    public init(tier: CatalogTier? = nil, contentSize: ContentSizeCategory = .large, reduceMotion: Bool = false) { self.tier = tier; self.contentSize = contentSize; self.reduceMotion = reduceMotion }
    public func body(context: ComponentContext) -> RenderElement {
        let entries = tier.map(PrismCatalog.entries(tier:)) ?? PrismCatalog.entries
        var element = VStack(alignment: .start, spacing: 8) {
            Text("Prism Catalog — \(entries.count) isolated examples").font(.heading)
            for entry in entries { Text("\(entry.tier.rawValue.uppercased()) · \(entry.component) · \(entry.states.joined(separator: ", "))") }
            AnimationInspector(isVisible: true)
        }.padding(20).render(in: context)
        element.props.custom["catalogTier"] = tier?.rawValue ?? "all"
        element.props.custom["contentSize"] = contentSize.rawValue
        element.props.custom["reduceMotion"] = reduceMotion ? "true" : "false"
        return element
    }
}

/// Persisted state for a catalog host. A host keeps this reference while the
/// render tree is rebuilt, so selecting an example or changing a control never
/// resets the developer's current scenario.
public final class PrismCatalogStore: @unchecked Sendable {
    public var selectedEntryID: String?
    public var tier: CatalogTier?
    public var contentSize: ContentSizeCategory
    public var reduceMotion: Bool
    public var highContrast: Bool
    public var themeName: String
    public private(set) var interactionCount: Int = 0

    public init(
        tier: CatalogTier? = nil,
        contentSize: ContentSizeCategory = .large,
        reduceMotion: Bool = false,
        highContrast: Bool = false,
        themeName: String = "light"
    ) {
        self.tier = tier
        self.contentSize = contentSize
        self.reduceMotion = reduceMotion
        self.highContrast = highContrast
        self.themeName = themeName
    }

    public func select(_ entry: CatalogEntry) { selectedEntryID = entry.id; interactionCount += 1 }
    public func select(id: String) { selectedEntryID = id; interactionCount += 1 }
    public func toggleReduceMotion() { reduceMotion.toggle(); interactionCount += 1 }
    public func toggleHighContrast() { highContrast.toggle(); interactionCount += 1 }
    public func setTheme(_ theme: String) { themeName = theme; interactionCount += 1 }
    public func setContentSize(_ size: ContentSizeCategory) { contentSize = size; interactionCount += 1 }
    public func recordInteraction() { interactionCount += 1 }
    public func selectedEntry(in entries: [CatalogEntry] = PrismCatalog.entries) -> CatalogEntry? {
        guard let selectedEntryID else { return nil }
        return entries.first { $0.id == selectedEntryID }
    }
}

/// Runnable catalog host composition used by iOS and macOS adapters.
/// The host exposes stable test IDs for navigation, controls, inspectors, and
/// the selected isolated example; platform hosts only need to mount this tree.
public struct PrismCatalogHost: Component {
    public let store: PrismCatalogStore

    public init(store: PrismCatalogStore = PrismCatalogStore()) { self.store = store }

    public func body(context: ComponentContext) -> RenderElement {
        let visibleEntries = store.tier.map(PrismCatalog.entries(tier:)) ?? PrismCatalog.entries
        let selected = store.selectedEntry(in: visibleEntries)

        var root = VStack(alignment: .stretch, spacing: 12) {
            Text("Prism Catalog — (visibleEntries.count) isolated examples")
                .font(.heading)
                .testID("catalog.title")
            HStack(spacing: 8) {
                Button("Light", variant: store.themeName == "light" ? .primary : .outline) { store.setTheme("light") }
                    .testID("catalog.theme.light")
                Button("Dark", variant: store.themeName == "dark" ? .primary : .outline) { store.setTheme("dark") }
                    .testID("catalog.theme.dark")
                Button("Contrast", variant: store.highContrast ? .primary : .outline) { store.toggleHighContrast() }
                    .testID("catalog.control.contrast")
                Button("Motion", variant: store.reduceMotion ? .secondary : .outline) { store.toggleReduceMotion() }
                    .testID("catalog.control.motion")
            }
            HStack(spacing: 8) {
                for tier in CatalogTier.allCases {
                    Button(tier.rawValue.uppercased(), variant: store.tier == tier ? .primary : .outline) {
                        store.tier = tier; store.recordInteraction()
                    }.testID("catalog.tier.\(tier.rawValue)")
                }
            }
            HStack(alignment: .start, spacing: 16) {
                VStack(alignment: .stretch, spacing: 4) {
                    Text("Examples").font(.heading)
                    for entry in visibleEntries {
                        Button(entry.component, variant: selected?.id == entry.id ? .secondary : .ghost, size: .sm) {
                            store.select(entry)
                        }
                        .testID("catalog.entry.\(entry.id)")
                        .accessibilityLabel("Open \(entry.component) example")
                    }
                }
                .testID("catalog.entry-list")

                VStack(alignment: .stretch, spacing: 8) {
                    if let selected {
                        CatalogExampleScreen(entry: selected, store: store)
                            .testID("catalog.example.\(selected.id)")
                    } else {
                        Empty(title: "Select an example", description: "Choose a component to inspect its real stateful scenario.")
                            .testID("catalog.empty")
                    }
                    CatalogInspector(store: store, selected: selected)
                }
                .testID("catalog.detail")
            }
        }
        .padding(20)
        .render(in: context)
        root.props.custom["catalogTier"] = store.tier?.rawValue ?? "all"
        root.props.custom["selectedEntry"] = store.selectedEntryID ?? ""
        root.props.custom["contentSize"] = store.contentSize.rawValue
        root.props.custom["reduceMotion"] = store.reduceMotion ? "true" : "false"
        root.props.custom["highContrast"] = store.highContrast ? "true" : "false"
        root.props.custom["theme"] = store.themeName
        root.props.custom["interactionCount"] = String(store.interactionCount)
        return root
    }
}

private struct CatalogInspector: Component {
    let store: PrismCatalogStore
    let selected: CatalogEntry?

    func body(context: ComponentContext) -> RenderElement {
        VStack(alignment: .stretch, spacing: 4) {
            Text("Inspectors").font(.heading)
            Text("Tree: \(selected?.component ?? "none")")
            Text("Layout: size=\(store.contentSize.rawValue), contrast=\(store.highContrast ? "high" : "standard")")
            Text("Animation: reduceMotion=\(store.reduceMotion)")
            Text("Theme: \(store.themeName)")
        }
        .padding(12)
        .testID("catalog.inspectors")
        .render(in: context)
    }
}

private struct CatalogExampleScreen: Component {
    let entry: CatalogEntry
    let store: PrismCatalogStore

    func body(context: ComponentContext) -> RenderElement {
        let sampleBinding = Binding<String>(get: { store.selectedEntryID ?? entry.id }, set: { store.select(id: $0) })
        switch entry.component {
        case "Badge": return Badge("Ready").render(in: context)
        case "Card": return Card { CardHeader { Text("Card example") }; CardContent { Text("Stateful isolated content") } }.render(in: context)
        case "Button": return Button("Activate", action: { store.recordInteraction() }).testID("example.action").render(in: context)
        case "Input": return Input("Name", text: sampleBinding).render(in: context)
        case "CodeBlock": return CodeBlock(code: "let prism = true", language: "swift").render(in: context)
        case "Kbd": return Kbd("⌘K").render(in: context)
        case "Skeleton": return Skeleton().render(in: context)
        case "Empty": return Empty(title: "No results", actionTitle: "Retry", onAction: { store.recordInteraction() }).render(in: context)
        case "Accordion":
            let expanded = Binding<Set<String>>(get: { store.selectedEntryID == entry.id ? [entry.id] : [] }, set: { _ in store.select(entry) })
            return Accordion(items: [AccordionItem(id: entry.id, title: "Details") { Text("Accordion content") }], expandedIDs: expanded).render(in: context)
        case "AspectRatio": return AspectRatio(16.0 / 9.0) { Text("16:9") }.render(in: context)
        default:
            return Card { CardHeader { Text(entry.component) }; CardContent { Text("\(entry.category) · \(entry.states.joined(separator: ", "))") } }.render(in: context)
        }
    }
}
