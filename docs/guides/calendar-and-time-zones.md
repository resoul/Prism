# Calendar and Time-zone Service (P3)

Use `CalendarService` for civil dates, locale-aware formatting, calendar arithmetic, DST-safe resolution, and deterministic tests:

```swift
let service = CalendarService(timeZone: TimeZone(identifier: "UTC")!, clock: FixedPrismClock(now: instant))
let leapDay = try service.date(from: DateComponents(year: 2024, month: 2, day: 29))
let label = service.format(leapDay)
```

`date(from:)` rejects nonexistent local times. `resolve(_:policy:repeatedTimePolicy:)` supports strict or next-valid DST gaps and explicit first/last fold selection. Inject `FixedPrismClock` in tests; production uses `SystemPrismClock`.

## Extending

Wrap the service in an application boundary to add business calendars or host integrations. Keep EventKit, date-picker views, and mutable formatter state outside Prism's public API.

## Limitations

No UI date picker, EventKit sync, recurring-event store, or network transport is included. Cancellation is represented by the consumer task and should stop work before rendering state.
