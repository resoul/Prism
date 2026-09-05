# ADR 0039: Command Palette Registry

`CommandRegistry` owns stable IDs, scope, enabled state, and deterministic shortcut resolution. `CommandPaletteEngine` owns cancellable search state and accepts only enabled results; stale provider responses are ignored when the query changes. Executing a palette result returns its ID for an application-owned action dispatcher—Prism never executes arbitrary closures.
