# Extending Showcase Theme Presets

Prism's theme architecture uses `PrismConfig` to resolve pure design tokens topologically, allowing applications to declare custom theme presets alongside the bundled presets (`Light`, `Dark`, `Midnight`, `Forest`, and `Sand`) without mutating global library defaults.

## Bundled Presets Overview

The showcase includes five presets:
1. **Light**: Crisp white background, dark slate text, high-contrast violet/indigo primary.
2. **Dark**: Deep slate background (`#060910`), bright foreground (`#F8FAFC`), indigo primary.
3. **Midnight**: Rich deep navy blue (`#0A1128`), bright ice blue primary (`#38BDF8`), dark navy borders (`#253248`).
4. **Forest**: Fresh nature palette with soft cream/sage background (`#F4F7F4`), deep emerald green primary (`#2D6A4F`), and pine text.
5. **Sand**: Warm desert earth palette with warm linen background (`#FAF7F2`), terracotta primary (`#C86D51`), and warm taupe muted tones.

## Adding a 6th Custom Theme Preset

To declare and register an additional theme (for example, `Lavender` or a custom brand theme):

### 1. Define the ThemeID and Semantic Color Palette

```swift
import PrismUI

// 1. Declare the new ThemeID
extension ThemeID {
    public static let lavender = ThemeID("lavender")
}

// 2. Define the complete semantic token palette
public let lavenderColors = ThemeColors(
    background: Color.hex("#F7F5FB"),
    foreground: Color.hex("#2E2836"),
    primary: Color.hex("#7C3AED"),
    primaryForeground: .white,
    secondary: Color.hex("#EDE9FE"),
    secondaryForeground: Color.hex("#2E2836"),
    muted: Color.hex("#EDE9FE"),
    mutedForeground: Color.hex("#797189"),
    border: Color.hex("#DDD6FE"),
    destructive: Color.hex("#DC2626"),
    destructiveForeground: .white,
    accent: Color.hex("#DDD6FE"),
    accentForeground: Color.hex("#5B21B6"),
    custom: [
        "surface": Color.hex("#FFFFFF"),
        "focus": Color.hex("#7C3AED")
    ]
)
```

### 2. Create the ThemeDefinition and Append to PrismConfig

```swift
let lavenderDefinition = ThemeDefinition(
    id: .lavender,
    parentID: nil,
    colors: Colors(
        background: lavenderColors.background,
        foreground: lavenderColors.foreground,
        primary: lavenderColors.primary,
        primaryForeground: lavenderColors.primaryForeground,
        secondary: lavenderColors.secondary,
        secondaryForeground: lavenderColors.secondaryForeground,
        muted: lavenderColors.muted,
        mutedForeground: lavenderColors.mutedForeground,
        border: lavenderColors.border,
        destructive: lavenderColors.destructive,
        destructiveForeground: lavenderColors.destructiveForeground,
        accent: lavenderColors.accent,
        accentForeground: lavenderColors.accentForeground,
        custom: lavenderColors.custom
    )
)

// Append to bundled definitions:
var definitions = ShowcaseConfig.bundled.definitions
definitions.append(lavenderDefinition)

let customAppConfig = try PrismConfig(
    baseTokens: ShowcaseConfig.bundled.baseTokens,
    definitions: definitions
)
```

### 3. Resolve and Activate the Theme Dynamically

```swift
// Resolve the theme from the configuration:
let theme = try customAppConfig.resolveTheme(for: .lavender)

// In HostUIView (iOS) or HostNSView (macOS):
hostView.setTheme(theme)
```

The host view immediately triggers a render pass through `PrismHostEngine`. All background colors, foreground text, borders, and accents update dynamically across the live layer tree and overlays, without losing the user's current navigation state or input form drafts.
