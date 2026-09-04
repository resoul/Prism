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
