# P2 Components Guide: Data Display, Feedback, and Layout

This guide explains how to use the Phase 05 P2 components introduced in Prism: `Kbd`, `CodeBlock`, `Skeleton`, `Empty`, `Table`, `Timeline`, `HoverCard`, `AspectRatio`, and `Accordion` / `Collapsible`.

---

## 1. Keyboard Badges (`Kbd`)

Use `Kbd` to visually represent keyboard keys and shortcuts in documentation or tooltips:

```swift
HStack(spacing: 6) {
    Kbd("⌘")
    Kbd("K")
    Text("to open command palette")
}
```

- Standard symbols (`⌘`, `⇧`, `⌥`, `⌃`, `↵`, `⎋`, `␣`) automatically map to human-readable screen reader labels (e.g. "Command", "Return").
- Custom labels can be provided via `Kbd("P", accessibleLabel: "Key P")`.

---

## 2. Syntax Snippets (`CodeBlock`)

`CodeBlock` renders multi-line code snippets with monospace typography, optional line numbers, and an optional copy button:

```swift
CodeBlock(
    code: """
    func greet() {
        print("Hello, Prism!")
    }
    """,
    language: "swift",
    showLineNumbers: true,
    onCopy: {
        // Handle copy to clipboard
    }
)
```

**Security Note:** `CodeBlock` renders pure formatted text nodes and never evaluates or executes script templates.

---

## 3. Placeholder Shimmer Loaders (`Skeleton`)

`Skeleton` provides visual loading indicators while asynchronous resources are loading:

```swift
// Circular avatar placeholder
Skeleton(shape: .circle, width: 48, height: 48)

// Text line placeholders
VStack(spacing: 8) {
    Skeleton(shape: .rounded(radius: 4), width: 200, height: 16)
    Skeleton(shape: .rounded(radius: 4), width: 140, height: 14)
}
```

**Reduce Motion Support:** When `context.environment.reduceMotion` is `true`, pulse animations are automatically suppressed, displaying a low-contrast static placeholder.

---

## 4. Empty State View (`Empty`)

`Empty` displays a turnkey placeholder when lists, queries, or selections have no data:

```swift
Empty(
    title: "No Notifications",
    description: "You're all caught up! New messages will appear here.",
    iconName: "bell.slash",
    actionTitle: "Refresh",
    onAction: {
        refreshFeed()
    }
)
```

---

## 5. Static Tables (`Table`)

`Table` formats multi-column in-memory tabular datasets up to ~1,000 rows:

```swift
Table(
    columns: [
        TableColumn(title: "Task", width: 160, alignment: .leading),
        TableColumn(title: "Owner", width: 120, alignment: .leading),
        TableColumn(title: "Status", width: 80, alignment: .center)
    ],
    rows: [
        TableRow(cells: ["Navigation Subsystem", "Alex", "Done"]),
        TableRow(cells: ["Metal SDF Shaders", "Sam", "Done"]),
        TableRow(cells: ["P2 Catalog", "Resoul", "Review"])
    ],
    isStriped: true,
    showBorders: true
)
```

*Note: For 10,000+ rows, use `LazyList` with row virtualization.*

---

## 6. Chronological Milestones (`Timeline`)

`Timeline` renders vertical progress milestones:

```swift
Timeline(items: [
    TimelineItem(
        title: "Order Placed",
        timestamp: "10:30 AM",
        description: "Your order was received.",
        status: .completed
    ),
    TimelineItem(
        title: "Out for Delivery",
        timestamp: "1:15 PM",
        description: "Courier is on the way.",
        status: .active
    ),
    TimelineItem(
        title: "Delivered",
        timestamp: nil,
        description: "Package received at doorstep.",
        status: .upcoming
    )
])
```

---

## 7. Contextual Previews (`HoverCard`)

`HoverCard` anchors a floating card to a target element and projects it into the `.floating` overlay layer:

```swift
HoverCard(
    placement: .bottom,
    isOpen: isCardOpen,
    anchor: {
        Text("@alex (hover me)")
    },
    card: {
        VStack(spacing: 4) {
            Text("Alex Morgan")
                .font(.heading)
            Text("Software Engineer · Infrastructure")
                .font(.body)
        }
    }
)
```

---

## 8. Fixed Ratio Containers (`AspectRatio`)

`AspectRatio` constrains child dimensions to a mathematical aspect ratio ($w / h$):

```swift
// 16:9 Aspect Ratio container
AspectRatio(16.0 / 9.0, contentMode: .fit) {
    Image(source: .url(thumbnailURL))
}

// Fluent modifier syntax:
MyCardView()
    .aspectRatio(4.0 / 3.0)
```

---

## 9. Disclosures & Accordions (`Collapsible`, `Accordion`)

### Collapsible
A single collapsible disclosure panel:

```swift
Collapsible(
    title: "Advanced Settings",
    isExpanded: $showAdvanced
) {
    Text("Custom API endpoint configuration...")
}
```

### Accordion
A coordinator for multiple collapsible sections with `.single` or `.multiple` expansion modes:

```swift
Accordion(
    items: [
        AccordionItem(id: "faq-1", title: "What is Prism?") {
            Text("Prism is a cross-platform pure Swift UI framework.")
        },
        AccordionItem(id: "faq-2", title: "Does it leak platform types?") {
            Text("No, public APIs never leak UIKit or AppKit.")
        }
    ],
    mode: .single,
    expandedIDs: $expandedSectionIDs
)
```

---

## 10. P2 data entry

P2 entry controls use the existing `Binding` / `TextDocument` / focus path; they do not create a second input engine. `NumberField`, `Slider`, `RangeSlider`, and `Stepper` clamp values to their declared range and round updates to `step`. Their hosts expose increment/decrement actions for keyboard and assistive technology.

```swift
NumberField("Quantity", value: quantity, range: 0...10, step: 1)
Slider(value: opacity, in: 0...1, step: 0.05, label: "Opacity")
ToggleGroup(options: densityOptions, selected: density, mode: .single)
```

`Select` is Prism's platform-neutral menu presentation; `NativeSelect` requests a native host presentation through an internal adapter. Neither public API exposes UIKit, AppKit, or SwiftUI types. Searchable and multi-select menus are P3 work, not hidden options in this API.

```swift
Select("Plan", selection: plan, options: [
    SelectionOption("free", label: "Free"),
    SelectionOption("pro", label: "Pro")
])
```

Use `InputGroup` for leading/trailing adornments around one `Input`, and `ButtonGroup` for related actions. `P2DataEntryDemoScreen` provides an isolated catalog fixture including controlled values, compact grouping, validation-capable numeric bounds, and focusable controls.
