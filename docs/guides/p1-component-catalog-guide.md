# P1 Component Catalog & Style Contracts Guide

This guide describes how to use and customize Prism's P1 design system components: Data Display (`Badge`, `Label`, `Avatar`, `Card`, `IconTile`), Feedback (`Alert`, `Spinner`), Navigation (`Tabs`), Overlays (`Dialog`, `Tooltip`), and Layout primitives (`Divider`, `Frame`).

---

## 1. Data Display Components

### Badge
Semantic status and count indicator:
```swift
Badge("New", variant: .default)
Badge("Pending", variant: .secondary)
Badge("Failed", variant: .destructive, size: .sm)
Badge("Outline", variant: .outline)
```

### Label
Composite pairing an icon and text with automatic accessibility label synthesis:
```swift
Label("Favorites", systemImage: "heart.fill")
Label("Custom Cloud", icon: .svg(named: "cloud", bundle: "Assets"))
```

### Avatar
Displays a remote/bundled profile image with automatic circular clipping and initials fallback:
```swift
Avatar(url: user.avatarURL, size: .lg)
Avatar(initials: "TC", size: .md)
```

### Card
Structured container with composable header, body, and footer sections:
```swift
Card {
    CardHeader {
        CardTitle("Account Summary")
        CardDescription("Recent transactions and active balance")
    }
    CardContent {
        Text("$1,248.50")
    }
    CardFooter {
        Button("View Details", variant: .outline) { ... }
    }
}
```

### IconTile
Rounded square accent container showcasing an icon with optional badge:
```swift
IconTile(systemImage: "bell.fill", size: 48.0, iconSize: 24.0, badgeCount: 3)
```

---

## 2. Feedback Components

### Alert
Semantic notification callout:
```swift
Alert(title: "Payment Received", description: "Your order is being processed.", variant: .success)
Alert(title: "Session Expired", description: "Please sign in again.", variant: .destructive)
```

### Spinner
Activity indicator with automatic Reduce Motion adaptation:
```swift
Spinner(size: .md)
```
*Note: When system `reduceMotion` is enabled, continuous rotation animation is automatically replaced by a static accessible loading symbol.*

---

## 3. Navigation (`Tabs`)

Declarative tab switching with `tab` and `tabpanel` accessibility linking:
```swift
enum FeedTab: String, CaseIterable, TabItem {
    case posts, media, likes
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

Tabs(FeedTab.allCases, selection: $selectedTab) { tab in
    switch tab {
    case .posts: PostListView()
    case .media: MediaGridView()
    case .likes: LikesListView()
    }
}
```

---

## 4. Modal Overlays (`Dialog` & `Tooltip`)

### Dialog
Modal dialog with dimmed backdrop and focus trap:
```swift
Dialog(isPresented: $showDialog, title: "Delete Item") {
    Text("This action cannot be undone.")
} actions: {
    Button("Cancel", variant: .outline) { showDialog = false }
    Button("Delete", variant: .destructive) { performDelete() }
}
```

### Tooltip
Contextual hint anchored to an element in the floating overlay tier:
```swift
Tooltip("Click to copy email address", placement: .top, isVisible: isHovered) {
    Button("user@example.com") { ... }
}
```

---

## 5. Layout Primitives (`Divider`, `Frame`)

### Divider
Hairline separator adapting to theme border color:
```swift
Divider(.horizontal, thickness: 1.0)
Divider(.vertical, thickness: 2.0)
```

### Frame
Explicit dimension and alignment boundaries:
```swift
Frame(width: 300, height: 200, alignment: .start) {
    ContentView()
}
```

---

## 6. Extensible Style Contracts

Customize visual appearance without breaking accessibility:

```swift
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonConfiguration, context: ComponentContext) -> RenderElement {
        RenderElement(
            id: ElementID(typeName: "BrandButton"),
            kind: .stack(axis: .horizontal, alignment: .center, spacing: 6.0),
            modifiers: [
                .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20)),
                .background(Color.hex("#FF5500")),
                .opacity(configuration.isEnabled ? 1.0 : 0.4)
            ],
            children: [configuration.label]
        )
    }
}
```
