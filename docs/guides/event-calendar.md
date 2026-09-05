# EventCalendar (P3)

Create stable-ID events and derive overlap columns:

```swift
var model = EventCalendarModel(events: events)
let frames = model.layout(viewport: dayInterval)
_ = model.reschedule(id: eventID, start: newStart, end: newEnd)
```

All-day events are excluded from timed overlap columns. Use `cancelled: true` during a cancelled drag/keyboard operation and preserve the previous event in your host state.

## Extending

Map frame columns to a host timeline, keep IDs stable across updates, and apply timezone/DST policy through CalendarService before rescheduling. Add recurring-event expansion in a separate repository layer.

## Limitations

No native calendar integration, recurring rules, reminders, persistence, or event editing UI is included. Overlap layout is intentionally lightweight for viewport-sized sets.
