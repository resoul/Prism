# ADR 0032: DateSelector Bounds and Focus

`DateSelector` is a value-type single-date state machine backed by `Binding<Date>` and `CalendarService`. Minimum/maximum checks happen before selection; keyboard/touch hosts use `moveDay(by:)`, and `cancel()` restores the committed selection before focus is returned by the host. Popover presentation is represented as state, not a platform view.

Event scheduling and EventKit remain out of scope. The additive API can be replaced by a host-specific picker without changing calendar arithmetic contracts.
