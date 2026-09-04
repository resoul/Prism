# Component State, Two-Way Binding, and Lifecycle Guide

This guide covers local component state management, two-way bindings, asynchronous lifecycle tasks (`EffectScope`), and state ownership boundaries in Prism.

---

## 1. State Ownership Tiers

Prism organizes state into four explicit tiers:

| Tier | Name | Scope & Retention | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **Tier 1** | `appStore` | Global / Multi-screen via Flux `CurrentValue` | User session, auth tokens, domain models, carts |
| **Tier 2** | `screenState` | Route / Navigation container | Active tabs, scroll positions, navigation parameters |
| **Tier 3** | `componentState` | `MountedNode` / ElementID-scoped | Input draft, expand/collapse toggles, hover flags |
| **Tier 4** | `keyedListItemState` | Stable row key in virtual lists | Row selection, swipe action state, row inline edits |

---

## 2. Component State (`ComponentStateStore`)

Local component state lives in `MountedNode.state(name:default:)`.
- The `default` closure is executed **only once** on initial mount.
- State values survive parent re-renders when the element identity (`ElementID`) is preserved.
- When an element is unmounted or replaced with an element of a different key/type, the stored state is automatically purged.

```swift
let countBinding = node.state(name: "counter") { 0 }
countBinding.wrappedValue += 1
```

---

## 3. Two-Way Binding (`Binding<Value>`)

`Binding<Value>` enables reading and writing values across component boundaries with safety guarantees:

### Feedback Loop Prevention
`Binding.setIfChanged(_:)` checks whether `wrappedValue != newValue` before calling the underlying setter closure:

```swift
binding.setIfChanged(newValue)
```

### Dynamic Member Lookup & Projections
Key-path dynamic member lookup allows accessing nested model fields seamlessly:

```swift
struct UserProfile: Sendable {
    var name: String
    var email: String
}

let profileBinding: Binding<UserProfile> = ...
let nameBinding: Binding<String> = profileBinding.name
```

### Projections & Subscripts
- **Map:** `binding.map(get: { $0.uppercased() }, set: { $0.lowercased() })`
- **Optional Fallback:** `optionalBinding[default: "N/A"]`
- **Collection Index:** `itemsBinding[0]`

---

## 4. Lifecycle-Scoped Effects (`EffectScope`)

`EffectScope` manages asynchronous tasks and mount/unmount hooks tied to the lifecycle of a `MountedNode`.

### Async Tasks with Automatic Cancellation
Launch async operations using `.task(id:priority:operation:)`:
- If another task is launched with the same `id`, any running task with that `id` is automatically cancelled with reason `.idChanged`.
- When the `MountedNode` is unmounted, all running tasks are cancelled with reason `.unmounted`.

```swift
node.effectScope.task(id: "fetch_data") {
    let result = try await apiClient.fetchDetails()
    // process result
}
```

### Appear & Disappear Hooks
Register actions that fire when the node enters or leaves the active scene:

```swift
node.effectScope.onAppearActions.append {
    logger.debug("Component mounted")
}

node.effectScope.onDisappearActions.append {
    logger.debug("Component unmounted")
}
```

---

## 5. State Diagnostics (`StateInspector`)

Use `StateInspector.dump(for:)` to inspect active subscriptions, running async effects, and component state keys in test suites or debug tooling:

```swift
let diagnostics = StateInspector.dump(for: node)
print(diagnostics)
```
