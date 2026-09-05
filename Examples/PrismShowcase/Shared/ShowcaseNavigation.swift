import Foundation
import CoreGraphics
import PrismUI

/// The 7 canonical categories defined by the Showcase Contract.
public enum ShowcaseCategory: String, CaseIterable, Sendable, Identifiable {
    case foundations = "foundations"
    case dataDisplay = "data-display"
    case forms = "forms"
    case feedbackAndOverlays = "feedback-overlays"
    case navigation = "navigation"
    case layoutAndCollections = "layout-collections"
    case advancedData = "advanced-data"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .foundations: return "Foundations"
        case .dataDisplay: return "Data Display"
        case .forms: return "Forms"
        case .feedbackAndOverlays: return "Feedback & Overlays"
        case .navigation: return "Navigation"
        case .layoutAndCollections: return "Layout & Collections"
        case .advancedData: return "Advanced Data"
        }
    }

    public var description: String {
        switch self {
        case .foundations: return "Core primitives, typography, shapes, and tokens."
        case .dataDisplay: return "Badges, labels, avatars, cards, code blocks, and tables."
        case .forms: return "Buttons, inputs, toggles, selectors, and field validation."
        case .feedbackAndOverlays: return "Alerts, toasts, dialogs, drawers, popovers, and menus."
        case .navigation: return "Tabs, breadcrumbs, pagers, menus, and command palettes."
        case .layoutAndCollections: return "Grids, containers, scroll areas, and virtualization."
        case .advancedData: return "Data grids, calendars, trees, charts, and boards."
        }
    }

    public var iconSymbol: String {
        switch self {
        case .foundations: return "cube"
        case .dataDisplay: return "list.bullet.rectangle"
        case .forms: return "square.and.pencil"
        case .feedbackAndOverlays: return "bubble.left.and.bubble.right"
        case .navigation: return "arrow.triangle.branch"
        case .layoutAndCollections: return "rectangle.split.3x3"
        case .advancedData: return "chart.bar.xaxis"
        }
    }
}

/// Typed, stable routes for showcase navigation.
public enum ShowcaseRoute: Equatable, Hashable, Sendable {
    case welcome
    case categories
    case category(ShowcaseCategory)
    case component(id: String)
    case notFound(id: String)

    public var pathString: String {
        switch self {
        case .welcome: return "welcome"
        case .categories: return "categories"
        case .category(let cat): return "category/\(cat.rawValue)"
        case .component(let id): return "component/\(id)"
        case .notFound(let id): return "not-found/\(id)"
        }
    }

    public static func parse(path: String) -> ShowcaseRoute {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "welcome" {
            return .welcome
        }
        if trimmed == "categories" {
            return .categories
        }
        if trimmed == "counter" {
            return .component(id: "counter")
        }
        if trimmed.hasPrefix("category/") {
            let catID = String(trimmed.dropFirst("category/".count))
            if let category = ShowcaseCategory(rawValue: catID) {
                return .category(category)
            }
            return .notFound(id: catID)
        }
        if trimmed.hasPrefix("component/") {
            let compID = String(trimmed.dropFirst("component/".count))
            if ShowcaseRegistry.item(for: compID) != nil {
                return .component(id: compID)
            }
            return .notFound(id: compID)
        }
        if let category = ShowcaseCategory(rawValue: trimmed) {
            return .category(category)
        }
        if ShowcaseRegistry.item(for: trimmed) != nil {
            return .component(id: trimmed)
        }
        return .notFound(id: trimmed)
    }
}

/// Component development maturity rating.
public enum ComponentMaturity: String, Codable, Sendable, CaseIterable {
    case p0Core = "p0-core"
    case p1Standard = "p1-standard"
    case p2Advanced = "p2-advanced"
    case p3Experimental = "p3-experimental"

    public var title: String {
        switch self {
        case .p0Core: return "P0 Core"
        case .p1Standard: return "P1 Standard"
        case .p2Advanced: return "P2 Advanced"
        case .p3Experimental: return "P3 Experimental"
        }
    }
}

/// Target platform support capabilities for the component.
public struct PlatformCapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let iOS = PlatformCapabilities(rawValue: 1 << 0)
    public static let macOS = PlatformCapabilities(rawValue: 1 << 1)
    public static let touch = PlatformCapabilities(rawValue: 1 << 2)
    public static let pointer = PlatformCapabilities(rawValue: 1 << 3)
    public static let keyboard = PlatformCapabilities(rawValue: 1 << 4)

    public static let universal: PlatformCapabilities = [.iOS, .macOS, .touch, .pointer, .keyboard]
    public static let pointerAndTouch: PlatformCapabilities = [.iOS, .macOS, .touch, .pointer]
    public static let desktopOnly: PlatformCapabilities = [.macOS, .pointer, .keyboard]

    public var summary: String {
        var parts: [String] = []
        if contains(.iOS) { parts.append("iOS") }
        if contains(.macOS) { parts.append("macOS") }
        if contains(.touch) { parts.append("Touch") }
        if contains(.pointer) { parts.append("Pointer") }
        if contains(.keyboard) { parts.append("Keyboard") }
        return parts.joined(separator: ", ")
    }
}

/// Completion and verification status of a showcase component item.
public enum ShowcaseComponentStatus: Sendable, Hashable {
    case ready
    case incomplete(owner: String, gap: String)
    case grouped(parent: String)

    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    public var displayText: String {
        switch self {
        case .ready:
            return "Ready"
        case .incomplete(let owner, _):
            return "Planned (\(owner))"
        case .grouped(let parent):
            return "Grouped with \(parent)"
        }
    }
}

/// Metadata describing one catalog component item.
public struct ShowcaseComponentItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let publicSymbol: String
    public let category: ShowcaseCategory
    public let summary: String
    public let maturity: ComponentMaturity
    public let capabilities: PlatformCapabilities
    public let sourcePath: String
    public let documentationPath: String
    public let status: ShowcaseComponentStatus
    public let states: [String]
    public let availableVariants: [String]
    public let isInteractive: Bool

    public init(
        id: String,
        name: String,
        publicSymbol: String? = nil,
        category: ShowcaseCategory,
        summary: String,
        maturity: ComponentMaturity = .p1Standard,
        capabilities: PlatformCapabilities = .universal,
        sourcePath: String = "",
        documentationPath: String = "",
        status: ShowcaseComponentStatus = .ready,
        states: [String] = ["default", "interactive"],
        availableVariants: [String] = ["default"],
        isInteractive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.publicSymbol = publicSymbol ?? name
        self.category = category
        self.summary = summary
        self.maturity = maturity
        self.capabilities = capabilities
        self.sourcePath = sourcePath.isEmpty ? "Sources/PrismUI/\(category.title.replacingOccurrences(of: " ", with: ""))/\(name).swift" : sourcePath
        self.documentationPath = documentationPath.isEmpty ? "docs/components/\(id).md" : documentationPath
        self.status = status
        self.states = states
        self.availableVariants = availableVariants
        self.isInteractive = isInteractive
    }
}

/// Comprehensive registry of all audited components organized by the 7 categories.
public enum ShowcaseRegistry {
    public static let allCategories: [ShowcaseCategory] = ShowcaseCategory.allCases

    public static let allItems: [ShowcaseComponentItem] = [
        // Foundations
        ShowcaseComponentItem(id: "text", name: "Text", category: .foundations, summary: "Core typography primitive supporting roles and weights.", maturity: .p0Core, states: ["body", "heading", "display", "mono"]),
        ShowcaseComponentItem(id: "stack", name: "Stack", category: .foundations, summary: "Directional layout primitive with spacing and alignment.", maturity: .p0Core, states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "spacer", name: "Spacer", category: .foundations, summary: "Flexible space consumer expanding along parent axis.", maturity: .p0Core, states: ["flexible", "fixed"]),
        ShowcaseComponentItem(id: "rectangle", name: "Rectangle", category: .foundations, summary: "Geometric shape primitive with radius and fills.", maturity: .p0Core, states: ["filled", "stroked", "rounded"]),
        ShowcaseComponentItem(id: "circle", name: "Circle", category: .foundations, summary: "Circular geometric shape primitive.", maturity: .p0Core, states: ["filled", "stroked"]),
        ShowcaseComponentItem(id: "icon", name: "Icon", category: .foundations, summary: "Vector and symbol rendering primitive.", maturity: .p0Core, states: ["regular", "large", "colored"]),
        ShowcaseComponentItem(id: "image", name: "Image", category: .foundations, summary: "Asynchronous image rendering with content modes.", maturity: .p0Core, states: ["loaded", "loading", "placeholder"]),
        ShowcaseComponentItem(id: "tokens", name: "Theme Tokens", publicSymbol: "ThemeTokens", category: .foundations, summary: "Semantic color, typography, radius, and spacing tokens.", maturity: .p0Core, states: ["light", "dark", "midnight", "forest", "sand"]),

        // Data Display
        ShowcaseComponentItem(id: "badge", name: "Badge", category: .dataDisplay, summary: "Status and metadata indicator badge.", maturity: .p1Standard, states: ["default", "success", "warning", "destructive"], availableVariants: ["default", "outline", "subtle"]),
        ShowcaseComponentItem(id: "label", name: "Label", category: .dataDisplay, summary: "Icon and text pair for labels and menu items.", maturity: .p1Standard, states: ["leading", "trailing"]),
        ShowcaseComponentItem(id: "avatar", name: "Avatar", category: .dataDisplay, summary: "Image or initials display with fallback.", maturity: .p1Standard, states: ["image", "initials", "fallback"]),
        ShowcaseComponentItem(id: "card", name: "Card", category: .dataDisplay, summary: "Container for grouped content with header, body, and footer.", maturity: .p1Standard, states: ["elevated", "outlined", "interactive"]),
        ShowcaseComponentItem(id: "icontile", name: "IconTile", category: .dataDisplay, summary: "Tiled icon representation with optional label.", maturity: .p1Standard, states: ["standard", "prominent"]),
        ShowcaseComponentItem(id: "codeblock", name: "CodeBlock", category: .dataDisplay, summary: "Syntax-highlighted monospace code snippet viewer.", maturity: .p1Standard, states: ["swift", "json", "lineNumbers"]),
        ShowcaseComponentItem(id: "kbd", name: "Kbd", category: .dataDisplay, summary: "Keyboard shortcut and keycap badge display.", maturity: .p1Standard, states: ["single", "combination"]),
        ShowcaseComponentItem(id: "skeleton", name: "Skeleton", category: .dataDisplay, summary: "Animated shimmer loading placeholder.", maturity: .p1Standard, states: ["text", "circular", "card"]),
        ShowcaseComponentItem(id: "empty", name: "Empty", category: .dataDisplay, summary: "Empty state view with title, description, and action.", maturity: .p1Standard, states: ["default", "withAction"]),
        ShowcaseComponentItem(id: "table", name: "Table", category: .dataDisplay, summary: "Tabular data presentation with column headers.", maturity: .p1Standard, states: ["standard", "striped", "bordered"]),
        ShowcaseComponentItem(id: "timeline", name: "Timeline", category: .dataDisplay, summary: "Chronological event timeline presentation.", maturity: .p1Standard, states: ["completed", "inProgress", "pending"]),

        // Forms
        ShowcaseComponentItem(id: "counter", name: "Counter", category: .forms, summary: "Interactive counter, input, and scroll test playground.", maturity: .p1Standard, states: ["zero", "positive", "submitted"]),
        ShowcaseComponentItem(id: "button", name: "Button", category: .forms, summary: "Interactive tap target with variants, sizes, and states.", maturity: .p1Standard, states: ["primary", "secondary", "outline", "ghost", "destructive", "disabled"], availableVariants: ["primary", "secondary", "outline", "ghost", "destructive"]),
        ShowcaseComponentItem(id: "input", name: "Input", category: .forms, summary: "Single-line text entry with label and validation.", maturity: .p1Standard, states: ["default", "focused", "error", "disabled"]),
        ShowcaseComponentItem(id: "textarea", name: "Textarea", category: .forms, summary: "Multi-line text entry area.", maturity: .p1Standard, states: ["default", "withScroll", "disabled"]),
        ShowcaseComponentItem(id: "checkbox", name: "Checkbox", category: .forms, summary: "Binary or indeterminate toggle checkbox.", maturity: .p1Standard, states: ["checked", "unchecked", "indeterminate", "disabled"]),
        ShowcaseComponentItem(id: "radiogroup", name: "RadioGroup", category: .forms, summary: "Mutually exclusive single-choice option set.", maturity: .p1Standard, states: ["selected", "unselected", "disabled"]),
        ShowcaseComponentItem(id: "switch", name: "Switch", category: .forms, summary: "Binary state toggle switch.", maturity: .p1Standard, states: ["on", "off", "disabled"]),
        ShowcaseComponentItem(id: "toggle", name: "Toggle", category: .forms, summary: "Stateful toggle button.", maturity: .p1Standard, states: ["pressed", "unpressed"]),
        ShowcaseComponentItem(id: "field", name: "Field", category: .forms, summary: "Labeled form field wrapper with validation message.", maturity: .p1Standard, states: ["valid", "error", "required"]),
        ShowcaseComponentItem(id: "form", name: "Form", category: .forms, summary: "Structured form container with submission lifecycle.", maturity: .p1Standard, states: ["clean", "dirty", "submitting"]),
        ShowcaseComponentItem(id: "buttongroup", name: "ButtonGroup", category: .forms, summary: "Connected group of buttons with unified border.", maturity: .p1Standard, states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "numberfield", name: "NumberField", category: .forms, summary: "Numeric text field with step and boundary clamping.", maturity: .p1Standard, states: ["valid", "clamped", "disabled"]),
        ShowcaseComponentItem(id: "togglegroup", name: "ToggleGroup", category: .forms, summary: "Multi-select or single-select group of toggles.", maturity: .p1Standard, states: ["single", "multiple"]),
        ShowcaseComponentItem(id: "slider", name: "Slider", category: .forms, summary: "Continuous or stepped value slider.", maturity: .p1Standard, states: ["minimum", "middle", "maximum", "disabled"]),
        ShowcaseComponentItem(id: "rangeslider", name: "RangeSlider", category: .forms, summary: "Dual-thumb range selection slider.", maturity: .p1Standard, states: ["standard", "bounded"]),
        ShowcaseComponentItem(id: "stepper", name: "Stepper", category: .forms, summary: "Incremental step controller.", maturity: .p1Standard, states: ["active", "disabled"]),
        ShowcaseComponentItem(id: "rating", name: "Rating", category: .forms, summary: "Star or score rating selector.", maturity: .p1Standard, states: ["zero", "partial", "full"]),
        ShowcaseComponentItem(id: "select", name: "Select", category: .forms, summary: "Dropdown selection menu with custom options.", maturity: .p1Standard, states: ["closed", "open", "selected"]),
        ShowcaseComponentItem(id: "nativeselect", name: "NativeSelect", category: .forms, summary: "Host-native popup or picker button.", maturity: .p1Standard, states: ["default", "disabled"]),
        ShowcaseComponentItem(id: "combobox", name: "Combobox", category: .forms, summary: "Searchable combo box with filtered suggestions.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23m", gap: "Filtered suggestion dropdown overlay and async loading pending"), states: ["idle", "suggesting", "selected"]),
        ShowcaseComponentItem(id: "dateselector", name: "DateSelector", category: .forms, summary: "Date picker and calendar dropdown trigger.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23n", gap: "Calendar popover trigger and date binding pending"), states: ["collapsed", "expanded"]),
        ShowcaseComponentItem(id: "phoneinput", name: "PhoneInput", category: .forms, summary: "Formatted international telephone input.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23o", gap: "Country-aware formatting and dial-code picker pending"), states: ["formatted", "invalid"]),
        ShowcaseComponentItem(id: "inputotp", name: "InputOtp", category: .forms, summary: "Segmented one-time password code input.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23o", gap: "Segmented OTP visual cell focus and autofill paste pending"), states: ["empty", "partial", "complete"]),
        ShowcaseComponentItem(id: "fileupload", name: "FileUpload", category: .forms, summary: "File picker and drop target indicator.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23p", gap: "Drag-drop target highlighting and upload progress lifecycle pending"), states: ["idle", "dragging", "uploaded"]),

        // Feedback & Overlays
        ShowcaseComponentItem(id: "alert", name: "Alert", category: .feedbackAndOverlays, summary: "In-line callout banner with status iconography.", maturity: .p1Standard, states: ["info", "success", "warning", "destructive"], availableVariants: ["info", "success", "warning", "destructive"]),
        ShowcaseComponentItem(id: "spinner", name: "Spinner", category: .feedbackAndOverlays, summary: "Indeterminate loading activity indicator.", maturity: .p1Standard, states: ["spinning", "small", "large"]),
        ShowcaseComponentItem(id: "progress", name: "Progress", category: .feedbackAndOverlays, summary: "Determinate or indeterminate progress bar.", maturity: .p1Standard, states: ["zero", "fifty", "hundred"]),
        ShowcaseComponentItem(id: "toast", name: "Toast", category: .feedbackAndOverlays, summary: "Transient notification toast with dismiss action.", maturity: .p1Standard, states: ["queued", "visible", "dismissed"]),
        ShowcaseComponentItem(id: "dialog", name: "Dialog", category: .feedbackAndOverlays, summary: "Modal dialog overlay with backdrop and focus trap.", maturity: .p2Advanced, states: ["hidden", "visible"]),
        ShowcaseComponentItem(id: "tooltip", name: "Tooltip", category: .feedbackAndOverlays, summary: "Hover and focus informational tooltip.", maturity: .p2Advanced, states: ["idle", "hovered"]),
        ShowcaseComponentItem(id: "hovercard", name: "HoverCard", category: .feedbackAndOverlays, summary: "Rich popover triggered by hover intent.", maturity: .p2Advanced, states: ["idle", "preview"]),
        ShowcaseComponentItem(id: "sheet", name: "Sheet", category: .feedbackAndOverlays, summary: "Bottom or side drawer sheet modal.", maturity: .p2Advanced, states: ["collapsed", "expanded"]),
        ShowcaseComponentItem(id: "drawer", name: "Drawer", category: .feedbackAndOverlays, summary: "Slide-out navigation and content drawer.", maturity: .p2Advanced, states: ["leading", "trailing"]),
        ShowcaseComponentItem(id: "popover", name: "Popover", category: .feedbackAndOverlays, summary: "Anchored floating popover with arrow.", maturity: .p2Advanced, states: ["anchorTop", "anchorBottom"]),
        ShowcaseComponentItem(id: "dropdownmenu", name: "DropdownMenu", category: .feedbackAndOverlays, summary: "Contextual drop-down action menu.", maturity: .p2Advanced, states: ["closed", "opened"]),
        ShowcaseComponentItem(id: "contextmenu", name: "ContextMenu", category: .feedbackAndOverlays, summary: "Right-click or long-press contextual menu.", maturity: .p2Advanced, states: ["idle", "presented"]),

        // Navigation
        ShowcaseComponentItem(id: "tabs", name: "Tabs", category: .navigation, summary: "Segmented tab bar switching content views.", maturity: .p1Standard, states: ["horizontal", "vertical", "selected"]),
        ShowcaseComponentItem(id: "breadcrumb", name: "Breadcrumb", category: .navigation, summary: "Hierarchical page location breadcrumb trail.", maturity: .p1Standard, states: ["single", "nested", "active"]),
        ShowcaseComponentItem(id: "pagination", name: "Pagination", category: .navigation, summary: "Multi-page index and next/previous controls.", maturity: .p1Standard, states: ["firstPage", "midPage", "lastPage"]),
        ShowcaseComponentItem(id: "navigationmenu", name: "NavigationMenu", category: .navigation, summary: "Header navigation bar with nested sub-menus.", maturity: .p1Standard, states: ["horizontal", "activeItem"]),
        ShowcaseComponentItem(id: "menubar", name: "Menubar", category: .navigation, summary: "Desktop application menu bar.", maturity: .p3Experimental, capabilities: .desktopOnly, status: .incomplete(owner: "Task 23s", gap: "Desktop application menu hierarchy and keyboard navigation pending"), states: ["standard", "itemHighlighted"]),
        ShowcaseComponentItem(id: "commandpalette", name: "CommandPalette", category: .navigation, summary: "Search-driven command palette with fuzzy filtering.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23s", gap: "Global fuzzy command overlay and shortcut dispatch pending"), states: ["closed", "searchActive"]),

        // Layout & Collections
        ShowcaseComponentItem(id: "frame", name: "Frame", category: .layoutAndCollections, summary: "Constrained dimensional frame layout.", maturity: .p0Core, states: ["fixed", "minMax"]),
        ShowcaseComponentItem(id: "divider", name: "Divider", category: .layoutAndCollections, summary: "Visual separation line with optional label.", maturity: .p0Core, states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "aspectratio", name: "AspectRatio", category: .layoutAndCollections, summary: "Aspect ratio enforcer for media and cards.", maturity: .p0Core, states: ["sixteenByNine", "square", "fourByThree"]),
        ShowcaseComponentItem(id: "grid", name: "Grid", category: .layoutAndCollections, summary: "Column and row matrix grid container.", maturity: .p0Core, states: ["twoCol", "threeCol", "autoFit"]),
        ShowcaseComponentItem(id: "scrollarea", name: "ScrollArea", category: .layoutAndCollections, summary: "Scrollable viewport with custom scroll indicators.", maturity: .p0Core, states: ["vertical", "horizontal", "both"]),
        ShowcaseComponentItem(id: "responsivecontainer", name: "ResponsiveContainer", category: .layoutAndCollections, summary: "Adaptive layout switching based on container width.", maturity: .p0Core, states: ["compact", "medium", "expanded", "wide"]),
        ShowcaseComponentItem(id: "scaffold", name: "Scaffold", category: .layoutAndCollections, summary: "Screen scaffold with app bar, body, and bottom bar.", maturity: .p0Core, states: ["standard", "withDrawer"]),
        ShowcaseComponentItem(id: "accordion", name: "Accordion", category: .layoutAndCollections, summary: "Vertically stacked expandable disclosure panels.", maturity: .p2Advanced, states: ["collapsed", "expanded", "multiple"]),
        ShowcaseComponentItem(id: "collapsible", name: "Collapsible", category: .layoutAndCollections, summary: "Single disclosure panel with animated height.", maturity: .p2Advanced, states: ["closed", "opened"]),
        ShowcaseComponentItem(id: "resizable", name: "Resizable", category: .layoutAndCollections, summary: "Draggable split pane container.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23q", gap: "Interactive split bar dragging and ratio clamping pending"), states: ["horizontal", "vertical"]),
        ShowcaseComponentItem(id: "sortable", name: "Sortable", category: .layoutAndCollections, summary: "Drag-and-drop sortable collection.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23q", gap: "Drag-reorder gesture tracking and drop target animation pending"), states: ["idle", "dragging"]),
        ShowcaseComponentItem(id: "lazylist", name: "LazyList", category: .layoutAndCollections, summary: "Virtualized scrollable list recycling off-screen items.", maturity: .p1Standard, states: ["virtualized", "largeDataset"]),
        ShowcaseComponentItem(id: "lazygrid", name: "LazyGrid", category: .layoutAndCollections, summary: "Virtualized multi-column grid recycling cells.", maturity: .p1Standard, states: ["virtualized", "largeDataset"]),

        // Advanced Data
        ShowcaseComponentItem(id: "tree", name: "Tree", category: .advancedData, summary: "Hierarchical tree view with expandable nodes.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23r", gap: "Expandable tree row hierarchy and virtualized node recycling pending"), states: ["collapsed", "expanded", "selected"]),
        ShowcaseComponentItem(id: "datagrid", name: "DataGrid", category: .advancedData, summary: "High-performance virtualized 2D data table.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23t", gap: "2D column virtualization, sorting headers, and cell recycling pending"), states: ["sorted", "filtered", "scrolled"]),
        ShowcaseComponentItem(id: "filtereditor", name: "FilterEditor", category: .advancedData, summary: "Multi-rule structured filter builder.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23u", gap: "Composable filter expression builder and predicate validation pending"), states: ["empty", "withRules"]),
        ShowcaseComponentItem(id: "calendarview", name: "CalendarView", category: .advancedData, summary: "Month/week/day date calendar view.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23v", gap: "Month/week/day calendar grid rendering and weekday headers pending"), states: ["month", "week", "day"]),
        ShowcaseComponentItem(id: "eventcalendar", name: "EventCalendar", category: .advancedData, summary: "Interactive calendar with scheduled events.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23w", gap: "Time-slotted event layout and overlapping appointment columns pending"), states: ["eventsLoaded", "eventSelected"]),
        ShowcaseComponentItem(id: "chart", name: "Chart", category: .advancedData, summary: "Data series charting and visualization.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23x", gap: "Interactive data series charting and axis metrics rendering pending"), states: ["bar", "line", "pie"]),
        ShowcaseComponentItem(id: "kanban", name: "Kanban", category: .advancedData, summary: "Columnar Kanban board with draggable cards.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23y", gap: "Cross-column card dragging and column lane management pending"), states: ["todo", "inProgress", "done"]),
        ShowcaseComponentItem(id: "gantt", name: "Gantt", category: .advancedData, summary: "Project schedule Gantt chart with task dependencies.", maturity: .p3Experimental, status: .incomplete(owner: "Task 23z", gap: "Task dependency line rendering and schedule timeline zooming pending"), states: ["timeline", "taskZoomed"])
    ]

    /// Grouped helper slots and structural subcomponents documented alongside their owning component.
    public static let groupedItems: [ShowcaseComponentItem] = [
        ShowcaseComponentItem(id: "accordionitem", name: "AccordionItem", category: .layoutAndCollections, summary: "Expandable item slot for Accordion.", maturity: .p2Advanced, status: .grouped(parent: "Accordion")),
        ShowcaseComponentItem(id: "cardheader", name: "CardHeader", category: .dataDisplay, summary: "Top header container slot for Card.", maturity: .p1Standard, status: .grouped(parent: "Card")),
        ShowcaseComponentItem(id: "cardcontent", name: "CardContent", category: .dataDisplay, summary: "Main body content container slot for Card.", maturity: .p1Standard, status: .grouped(parent: "Card")),
        ShowcaseComponentItem(id: "cardfooter", name: "CardFooter", category: .dataDisplay, summary: "Bottom action footer slot for Card.", maturity: .p1Standard, status: .grouped(parent: "Card")),
        ShowcaseComponentItem(id: "cardtitle", name: "CardTitle", category: .dataDisplay, summary: "Title text container for Card.", maturity: .p1Standard, status: .grouped(parent: "Card")),
        ShowcaseComponentItem(id: "carddescription", name: "CardDescription", category: .dataDisplay, summary: "Descriptive subtitle container for Card.", maturity: .p1Standard, status: .grouped(parent: "Card")),
        ShowcaseComponentItem(id: "option", name: "Option", category: .forms, summary: "Selectable option entry for Select and Combobox.", maturity: .p1Standard, status: .grouped(parent: "Select")),
        ShowcaseComponentItem(id: "radioitem", name: "RadioItem", category: .forms, summary: "Individual radio button choice slot for RadioGroup.", maturity: .p1Standard, status: .grouped(parent: "RadioGroup"))
    ]

    public static func items(for category: ShowcaseCategory) -> [ShowcaseComponentItem] {
        allItems.filter { $0.category == category }
    }

    public static func item(for id: String) -> ShowcaseComponentItem? {
        let lowered = id.lowercased()
        if let direct = allItems.first(where: { $0.id.lowercased() == lowered }) {
            return direct
        }
        return groupedItems.first(where: { $0.id.lowercased() == lowered })
    }

    public static func item(forSymbol symbol: String) -> ShowcaseComponentItem? {
        let lowered = symbol.lowercased()
        if let direct = allItems.first(where: { $0.publicSymbol.lowercased() == lowered }) {
            return direct
        }
        return groupedItems.first(where: { $0.publicSymbol.lowercased() == lowered })
    }

    public static func search(query: String) -> [ShowcaseComponentItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return allItems }
        return allItems.filter {
            $0.name.lowercased().contains(trimmed) ||
            $0.id.lowercased().contains(trimmed) ||
            $0.publicSymbol.lowercased().contains(trimmed) ||
            $0.category.title.lowercased().contains(trimmed) ||
            $0.summary.lowercased().contains(trimmed)
        }
    }

    public static func categoryCount(for category: ShowcaseCategory) -> Int {
        items(for: category).count
    }

    public static func items(withStatus status: ShowcaseComponentStatus) -> [ShowcaseComponentItem] {
        allItems.filter { $0.status == status }
    }

    public static func items(withMaturity maturity: ComponentMaturity) -> [ShowcaseComponentItem] {
        allItems.filter { $0.maturity == maturity }
    }

    public static var allSymbols: [String] {
        (allItems + groupedItems).map { $0.publicSymbol }
    }
}

/// Navigation state snapshot tracking active route stack, selected items, search, and container dimensions.
public struct ShowcaseNavigationState: Equatable, Sendable {
    public var routeStack: [ShowcaseRoute]
    public var selectedCategory: ShowcaseCategory?
    public var selectedComponentID: String?
    public var searchQuery: String
    public var scrollOffsets: [String: Double]
    public var containerWidth: CGFloat
    public var breakpoint: Breakpoint

    public var currentRoute: ShowcaseRoute {
        routeStack.last ?? .welcome
    }

    public var isRoot: Bool {
        routeStack.count <= 1
    }

    public init(
        initialRoute: ShowcaseRoute = .welcome,
        containerWidth: CGFloat = 800.0
    ) {
        self.routeStack = [initialRoute]
        self.selectedCategory = nil
        self.selectedComponentID = nil
        self.searchQuery = ""
        self.scrollOffsets = [:]
        self.containerWidth = containerWidth
        self.breakpoint = Breakpoint.from(width: containerWidth)

        switch initialRoute {
        case .category(let cat):
            self.selectedCategory = cat
        case .component(let id):
            self.selectedComponentID = id
            if let item = ShowcaseRegistry.item(for: id) {
                self.selectedCategory = item.category
            }
        default:
            break
        }
    }

    /// Pushes a new route onto the stack, deduplicating identical consecutive requests.
    public mutating func push(route: ShowcaseRoute) {
        guard route != currentRoute else { return }
        routeStack.append(route)
        switch route {
        case .category(let cat):
            selectedCategory = cat
        case .component(let id):
            selectedComponentID = id
            if let item = ShowcaseRegistry.item(for: id) {
                selectedCategory = item.category
            }
        case .welcome, .categories:
            break
        case .notFound:
            break
        }
    }

    /// Pops the top route from the stack if not at root, restoring previous context.
    @discardableResult
    public mutating func pop() -> ShowcaseRoute? {
        guard routeStack.count > 1 else { return nil }
        let popped = routeStack.removeLast()
        if let current = routeStack.last {
            switch current {
            case .category(let cat):
                selectedCategory = cat
            case .component(let id):
                selectedComponentID = id
                if let item = ShowcaseRegistry.item(for: id) {
                    selectedCategory = item.category
                }
            case .categories:
                selectedComponentID = nil
            case .welcome:
                selectedCategory = nil
                selectedComponentID = nil
            case .notFound:
                break
            }
        }
        return popped
    }

    public mutating func setSearchQuery(_ query: String) {
        self.searchQuery = query
    }

    public mutating func clearSearch() {
        self.searchQuery = ""
    }

    public mutating func setScrollOffset(_ offset: Double, for key: String) {
        scrollOffsets[key] = max(0.0, offset)
    }

    public func scrollOffset(for key: String) -> Double {
        scrollOffsets[key] ?? 0.0
    }

    public mutating func setContainerWidth(_ width: CGFloat) {
        self.containerWidth = width
        self.breakpoint = Breakpoint.from(width: width)
    }
}
