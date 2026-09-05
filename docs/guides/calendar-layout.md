# Calendar Layout (P3)

Generate civil-date cells for a selected mode:

```swift
let layout = CalendarLayout(mode: .month, referenceDate: date, selectedDate: date, service: calendarService)
let days = layout.cells
```

Month boundaries are explicit through `isInDisplayedMonth`; `weekdaySymbols` follows the configured locale's first weekday. Week/day layouts use the same CalendarService timezone and remain deterministic across DST. Pass `isRTL` to communicate host presentation direction.

## Extending

Render `cells` with stable date IDs, route keyboard selection through the date values, and snapshot layouts with a fixed clock/service. Keep events and scheduling in a separate model.

## Limitations

No event markers, range selection, date picker popover, or native calendar view is included.
