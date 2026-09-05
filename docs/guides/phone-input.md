# PhoneInput (P3)

`PhoneInput` normalizes user editing into a canonical value when the input matches the selected country:

```swift
let us = PhoneMetadata.country(code: "US")!
let input = PhoneInput("Phone", value: phoneBinding, country: us)
input.normalize("(415) 555-2671") // +14155552671
```

`PhoneNumber` accepts international `+` values or local values with an explicit country. Validation covers characters and declared length ranges only; it does not verify ownership, reachability, or SMS capability.

## Extending

Add country metadata from an attributed numbering source, then add canonical and formatting fixtures. Keep caret, paste, delete, and keyboard behavior in the host text adapter.

## Limitations

The bundled metadata is intentionally small (US, CA, GB, DE, RO). Extensions and carrier/ownership checks are out of scope.
