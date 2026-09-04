# Prism Component API & Virtual Render Tree (VRT) Guide

Prism provides a lightweight, declarative component authoring layer that compiles into an immutable, pure value representation: the **Virtual Render Tree (VRT)**.

The VRT decoupled from platform rendering: `RenderElement` holds zero references to `CALayer`, `UIView`, `NSView`, or `SwiftUI`.

---

## 1. Minimal Example: Declarative Composition

Applications construct user interfaces using familiar declarative syntax without interacting directly with platform views or renderers:

```swift
import PrismUI

struct GreetingCard: Component {
    func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 12) {
            Text("Welcome to Prism")
                .font(.heading)
            
            HStack(spacing: 8) {
                Icon("sparkles")
                Text("Cross-platform declarative engine")
                    .font(.body)
            }
            
            Spacer(minLength: 16)
            
            Rectangle(cornerRadius: 8)
                .fill(.hex("#635BFF"))
                .frame(width: 140, height: 44)
        }
        .padding(16)
        .background(.hex("#FFFFFF"))
    }
}
```

---

## 2. Conditional & Dynamic Content

`@resultBuilder ComponentBuilder` natively supports conditionals (`if`, `if-else`), optionals, and collection loops:

```swift
import PrismUI

struct UserProfileView: Component {
    let user: User
    let notifications: [Notification]

    func body(context: ComponentContext) -> RenderElement {
        VStack(spacing: 16) {
            // Conditional branches
            if user.isPremium {
                HStack(spacing: 6) {
                    Icon("crown.fill")
                    Text("Premium Member")
                }
            } else {
                Text("Standard Account")
            }

            // Optional unwrapping
            if let bio = user.bio {
                Text(bio)
                    .lineLimit(3)
            }

            // Collection loops
            ForEach(notifications) { item in
                HStack {
                    Text(item.title)
                    Spacer()
                    Text(item.timestamp)
                }
                .padding(8)
            }
        }
    }
}
```

---

## 3. Structural Primitives: `Group` and `Empty`

Prism distinguishes visual elements from purely structural constructs:

- **`Group`**: Groups multiple children together syntactically without inserting a container or layout node into the render tree. During tree normalization, `Group` children are seamlessly inlined into the enclosing parent.
- **`Empty`**: Has zero layout and visual footprint (`[]`). It is eliminated during normalization.

```swift
VStack {
    Text("Header")
    
    Group {
        Text("Child 1")
        Text("Child 2")
    } // Inlined directly into VStack; no intermediate node created.
    
    Empty() // Zero footprint; pruned during tree normalization.
}
```

---

## 4. Keyed Identity & The `ForEach` Invariant

VRT reconciliation relies on stable three-tuple identities:
$$\text{Identity} = (\text{TypeName}, \text{Explicit Key}, \text{Sibling Position})$$

### Invariant: Server Data Requires Stable Explicit Keys

> [!CAUTION]
> **Array indices must never serve as persistent IDs for dynamic or server-driven data.**
> 
> Using array indices as IDs corrupts item identity during reordering, insertions, and deletions, causing active animations, input state, or subscriptions to bind to the wrong items.

Always pass a stable identifier from your data model:

```swift
// ✅ CORRECT: Explicit stable entity ID
ForEach(posts, id: \.id) { post in
    PostCard(post)
}

// ✅ CORRECT: Identifiable models with unique UUID/String
ForEach(users) { user in
    UserRow(user)
}

// ❌ FORBIDDEN FOR DYNAMIC DATA: Never use loop indices as stable IDs
// ForEach(0..<items.count) { index in ... }
```

---

## 5. Modifier Pipeline & Precedence Rules

Modifiers in Prism operate with pure value semantics: chained methods return a new `RenderElement` copy without mutating the receiver.

The modifier pipeline resolves deterministically:

1. **Paddings & Margins**: Accumulate outer values onto inner values.
   ```swift
   element.padding(10).padding(6) // Result: padding is 16
   ```
2. **Dimensions (`width`, `height`, `minWidth`, etc.)**: Later/outer constraints override earlier constraints.
   ```swift
   element.width(100).width(200) // Result: width is 200
   ```
3. **Opacity**: Multiplicative compositing, clamped to `[0.0, 1.0]`.
   ```swift
   element.opacity(0.5).opacity(0.5) // Result: opacity is 0.25
   ```
4. **Background & zIndex**: Later/outer values override earlier values.
5. **Key & TestID**: Set explicit identifiers (`id.key` and `props.testID`).

---

## 6. Debug Tree Inspection

For testing, snapshot assertions, and development diagnostics, every element tree can produce a visual dump:

```swift
let tree = VStack {
    Text("Hello")
    Spacer()
}.render()

print(tree.dumpTree())
```

Output:
```text
Stack(axis: vertical, alignment: start, spacing: 0.0)
  Text("Hello")
  Spacer
```
