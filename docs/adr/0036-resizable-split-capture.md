# ADR 0036: Resizable Split Capture

`ResizableSplit` is a pure value state machine. Ratios are clamped to min/max bounds; pointer capture converts extent deltas to ratios and can be committed or cancelled back to its origin. Keyboard resizing accepts a logical step and reverses it for RTL. Persistence is supplied by the consumer binding/store, keeping storage and host event types out of the core API.

The UI facade exposes separator semantics and state for accessibility adapters. Nested splits compose independently and do not share mutable global state.
