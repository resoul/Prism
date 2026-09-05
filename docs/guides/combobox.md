# Combobox (P3)

`Combobox` provides single selection with searchable options and bounded windows for virtualization:

```swift
var combo = Combobox("Country", selection: countryBinding, options: countries)
combo.search("uni")
let page = combo.visibleOptions(offset: 0, limit: 40)
combo.moveHighlight(by: 1)
_ = combo.commitHighlighted()
```

Disabled options are skipped during keyboard movement. `cancel()` clears the transient query and restores the closed state. Hosts should route IME composition and keyboard events to these methods and return focus to the input after commit/cancel.

## Extending

Wrap `Combobox` in a host adapter for platform text input and accessibility announcements. Keep selection in an app-owned `Binding`; use stable option values and a bounded `visibleOptions` window for 10k+ datasets.

## Limitations

Only single selection is supported. Native popup views, multiple selection, remote filtering, and asynchronous data loading are outside this task.
