# ADR 0031: Autocomplete Generation and Cancellation

`AutocompleteEngine` is an actor that owns text, suggestions, loading state, and a monotonically increasing generation. Each update cancels the prior debounced provider task; completion is accepted only when both generation and text still match. This prevents out-of-order responses from mutating current state. The UI facade stays free-text based and exposes no platform input types.

Providers are injected and may perform async work. Consumers call `cancel()` on blur or unmount; reversal is additive because `Combobox` remains the selection-oriented control.
