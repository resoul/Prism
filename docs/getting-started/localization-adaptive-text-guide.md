# Prism Localization, Dynamic Type & RTL Guide

Prism provides an adaptive text and layout engine designed to handle localization, right-to-left (RTL) reading directions, and accessibility text scaling (Dynamic Type) across Apple platforms without platform-specific UI checks in components.

---

## 1. Environment Inputs

Localization, text direction, and accessibility text sizing are environment inputs, not ad-hoc queries to UIKit or AppKit:

```swift
let env = LocalizationEnvironment(
    locale: Locale(identifier: "ar_EG"),
    contentSizeCategory: .extraLarge
)

// Natural reading direction is automatically inferred from the locale (e.g. Arabic -> RTL)
assert(env.layoutDirection == .rightToLeft)
```

---

## 2. Localized Strings & String Interpolation

Components receive `LocalizedStringKey` supporting typed parameters and interpolation:

```swift
let count = 5
let message: LocalizedStringKey = "You have \(count) unread messages"
```

- **Plural Rules:** `LocalizationBundle.shared.localizedPlural` resolves count-based templates adhering to English, Romance, and Slavic plural cardinality rules (`zero`, `one`, `few`, `many`, `other`).
- **Development vs Release Fallbacks:**
  - In development mode (`isDevelopmentMode = true`), missing translation keys are visibly flagged as `[MISSING: "key"]`.
  - In release mode, the fallback string or raw key is safely returned without crashing.
- **Pseudo-Localization:** Can be toggled on to stress-test UI layout elasticity by adding character accents and bracket expansions (`[--- Ħéłłó Ŵóŕłđ ---]`).

---

## 3. Dynamic Type & Clamped Typography Scaling

All text styles and custom fonts scale automatically with `ContentSizeCategory`:

```swift
// Resolves font size with Dynamic Type scaling and safety clamping
let scaledFont = theme.font(
    for: .body,
    contentSizeCategory: env.contentSizeCategory
)
```

- Standard text categories scale from `0.82x` (`.extraSmall`) to `1.36x` (`.extraExtraExtraLarge`).
- Accessibility tiers scale up to `3.40x` (`.accessibilityExtraExtraExtraLarge`).
- `DynamicTypeConfig` allows components to set minimum and maximum scaling limits to prevent clipping on constrained cards or banners.
- Line height scales proportionally with font size to preserve typographic rhythm.

---

## 4. Direction-Aware Layout (Leading vs Trailing)

Layouts use semantic direction-aware properties instead of hardcoded left/right:

```swift
let insets = DirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 24)

// In LTR: left = 16, right = 24
// In RTL: left = 24, right = 16
let physicalInsets = env.resolveInsets(insets)
```

Horizontal alignment resolves automatically:
- `.leading` maps to physical `.left` in LTR, and `.right` in RTL.
- `.trailing` maps to physical `.right` in LTR, and `.left` in RTL.

---

## 5. Thread-Safe Formatter Caching

`LocaleFormatterCache` eliminates expensive allocation of `DateFormatter` and `NumberFormatter` during layout and render passes:

```swift
let formattedDate = LocaleFormatterCache.shared.string(
    from: date,
    locale: env.locale,
    dateStyle: .medium
)

let priceString = LocaleFormatterCache.shared.formatCurrency(
    NSNumber(value: 99.99),
    currencyCode: "USD",
    locale: env.locale
)
```
