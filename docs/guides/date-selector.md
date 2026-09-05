# DateSelector (P3)

`DateSelector` provides bounded single-date selection on top of `CalendarService`:

```swift
var selector = DateSelector("Start date", selection: dateBinding, minimumDate: today)
selector.present()
selector.moveDay(by: 1)
_ = selector.select(selector.focusedDate)
```

Out-of-range dates are rejected. `cancel()` dismisses the popover state and restores the committed date; hosts should then return focus to the trigger/input. Locale and calendar formatting come from the injected `CalendarService`.

## Extending

Use a host adapter to render the calendar grid and route keyboard/touch events. Keep bounds and selection in the component, use stable day identities, and keep EventKit/event scheduling outside this API.

## Limitations

This task covers one date only. Date ranges, recurring events, event scheduling, and native picker views are not included.
