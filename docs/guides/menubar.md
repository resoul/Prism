# Menubar (P3)

Create commands with stable IDs and route keys through `MenubarModel`:

```swift
var model = MenubarModel(menus: [[MenuCommand(id: "save", title: "Save", shortcut: "s")]])
model.open(menu: 0)
let command = model.handle(.enter)
model.handle(.escape) // close and restore focus in the host
```

Disabled commands are skipped during arrow navigation. Shortcut conflicts resolve to the first enabled declaration. Touch/tvOS hosts may expose an alternate policy while preserving the same command IDs.

## Extending

Build a native adapter around the model, map platform key events to `MenuKey`, and restore `previousFocusID` after Escape or activation. Keep command actions in the application layer.

## Limitations

Submenus, native menu rendering, global shortcut registration, and platform-specific touch/tvOS affordances are intentionally outside this core contract.
