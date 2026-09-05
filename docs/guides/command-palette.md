# Command Palette (P3)

Register stable commands and inject a cancellable search provider:

```swift
let engine = CommandPaletteEngine { query in registry.commands.filter { $0.title.localizedCaseInsensitiveContains(query) } }
await engine.open(); await engine.search("save")
let snapshot = await engine.snapshotValue()
let commandID = await engine.execute(id: snapshot.results[0].id)
```

Scope-aware shortcut conflicts resolve to the first enabled declaration. Dismissal cancels in-flight search. The returned command ID must be dispatched by the application layer.

## Extending

Add commands through `CommandRegistry`, keep IDs stable, and map IDs to safe application actions. Hosts route keyboard events, focus restoration, and accessibility announcements around the semantic facade.

## Limitations

No arbitrary code execution, global shortcut registration, native popup, ranking policy, or remote provider transport is included.
