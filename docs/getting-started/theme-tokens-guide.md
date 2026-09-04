# Prism Design Tokens & Theme Guide

Prism provides a typed, immutable design token and theme configuration system. Tokens are configured declaratively using `PrismConfig` and resolved deterministically before the rendering pipeline.

---

## 1. Defining Application Theme Configuration

Themes and base tokens are authored using result builders without global mutable state:

```swift
import Prism

let appConfig = PrismConfig {
    // Base tokens inherited by all named themes
    BaseTokens {
        Typography(
            body: .init(family: "Inter", weight: .regular),
            heading: .init(family: "Inter", weight: .semibold),
            mono: .init(family: "JetBrains Mono", weight: .regular),
            display: .init(family: "Inter", weight: .bold),
            baseSize: 16,
            scale: .majorThird
        )

        Spacing(base: 4)
        Radius(sm: 6, md: 10, lg: 16, full: 9_999)
        Motion(fast: .milliseconds(150), normal: .milliseconds(250))
    }

    // Root light theme
    Theme(.light) {
        Colors(
            background: .hex("#FFFFFF"),
            foreground: .hex("#0F172A"),
            primary: .hex("#635BFF"),
            muted: .hex("#F1F5F9"),
            mutedForeground: .hex("#64748B"),
            border: .hex("#E2E8F0"),
            destructive: .hex("#E11D48")
        )
    }

    // Dark theme extending light
    Theme(.dark, extending: .light) {
        Colors(
            background: .hex("#0F172A"),
            foreground: .hex("#F8FAFC"),
            primary: .hex("#8B85FF"),
            muted: .hex("#1E293B"),
            mutedForeground: .hex("#94A3B8"),
            border: .hex("#334155"),
            destructive: .hex("#FB7185")
        )
    }

    // Custom midnight theme inheriting from dark and overriding specific slots
    Theme(.midnight, extending: .dark) {
        Colors(
            background: .hex("#020617"),
            muted: .hex("#0F172A"),
            primary: .hex("#38BDF8")
        )
    }
}

// Resolves the primary/default theme
let appTheme = Theme(config: appConfig)
```

---

## 2. Token Completeness & Inheritance Invariant

- Every child theme inherits all tokens (colors, typography, spacing, radius, shadow, motion) from its parent theme.
- After resolution, **every theme is 100% complete**. UI components never perform missing-token fallbacks during rendering.
- `PrismConfig.validate()` runs before rendering, catching:
  - Duplicate theme IDs (`ConfigValidationError.duplicateThemeID`)
  - Missing parent themes (`ConfigValidationError.missingParentTheme`)
  - Inheritance cycles (e.g. A -> B -> A) (`ConfigValidationError.inheritanceCycle`)
  - Negative spacing or radii (`ConfigValidationError.negativeSpacing`, `negativeRadius`)
  - Empty font family strings (`ConfigValidationError.emptyFontFamily`)
  - Malformed hex color strings (`ConfigValidationError.invalidHexColor`)

---

## 3. Theme Priority Hierarchy

Theme resolution follows a strict three-tier priority hierarchy:

1. **Subtree Override:** Explicit theme override set on a local component subtree (e.g. for previews, dialogs, or custom brand cards).
2. **Explicit Selection:** User preference selecting a specific named theme (`ThemeSelection.explicit(ThemeID)`).
3. **System Mapping:** `ThemeSelection.system` mapped to concrete `ThemeID`s via `SystemThemeMapping` according to the host OS `ColorScheme` (.light vs .dark).

---

## 4. Typography & CoreText Resolution

Font resolution converts abstract `(FontRole, TextStyle)` pairs into native `CTFont` objects:

```swift
let ctFont = theme.font(for: .heading2, role: .heading)
```

- **Thread Safety:** `FontResolver.shared` caches `CTFont` instances by `(family, weight, size, italic, tracking)` using a thread-safe lock.
- **System Fallback:** If a custom font family is not installed or available on the host system, `FontResolver` automatically degrades to the platform system UI font while preserving the requested weight and size.
- **Dynamic Registration:** Custom font assets can be registered dynamically at runtime from bundles or URLs via `FontLoader.register(fromURL:)`.
