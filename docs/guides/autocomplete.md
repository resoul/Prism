# Autocomplete (P3)

Use `AutocompleteEngine` for debounced, cancellable suggestions and render the result with `Autocomplete`:

```swift
let engine = AutocompleteEngine<String> { query in
    try await searchService.suggest(query)
}
await engine.update(text: query)
let snapshot = await engine.snapshot()
```

Every update cancels the previous request and stale responses are ignored. Call `cancel()` on blur, IME cancellation, or unmount. The control accepts free text; it does not require committing a suggestion.

## Extending

Inject a provider that checks task cancellation and returns stable suggestion values. Keep IME composition and keyboard event routing in the host adapter; publish snapshots into the component's `suggestions` input.

## Limitations

No remote transport, ranking policy, multi-column results, or platform-native input view is included. Debounce duration is configured in nanoseconds and defaults to 150 ms.
