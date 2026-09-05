# ADR 0033: PhoneInput Canonical Validation

Phone parsing is separated into `PhoneNumber` (pure canonical value) and `PhoneInput` (Binding/render facade). A small versioned metadata snapshot supplies country dial codes and length ranges; it validates shape only and never claims ownership or reachability. Canonical output is E.164-like (`+<dial><national>`), while formatting remains country-aware.

Metadata expansion must preserve attribution and update tests. Native keyboard/caret adapters remain host-owned.
