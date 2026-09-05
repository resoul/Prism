# ADR 0030: Combobox State and Virtualization

`Combobox` is a value-type state machine layered on `Binding` and `SelectionOption`. Query, expansion, and highlighted index are owned by the component; selection is owned by the consumer binding. Filtering is deterministic and `visibleOptions(offset:limit:)` bounds host rendering for large lists. Keyboard/IME adapters remain host-owned and no platform view types are exposed.

Cancellation is explicit through `cancel()`, which closes the popup and clears transient query state. Reversal is additive: consumers can continue using `Select` for non-searchable menus.
