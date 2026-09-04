import Foundation
import CoreGraphics

/// Semantic font roles in the design system.
public enum FontRole: Hashable, Sendable, CustomStringConvertible {
    case body
    case heading
    case mono
    case display
    case custom(String)

    public var description: String {
        switch self {
        case .body: return "body"
        case .heading: return "heading"
        case .mono: return "mono"
        case .display: return "display"
        case .custom(let name): return "custom(\(name))"
        }
    }
}

/// Standard font weights.
public enum FontWeight: String, Hashable, Sendable, CaseIterable {
    case thin
    case ultraLight
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    /// CoreText normalized weight value (-1.0 to 1.0).
    public var coreTextWeight: CGFloat {
        switch self {
        case .thin: return -0.6
        case .ultraLight: return -0.4
        case .light: return -0.2
        case .regular: return 0.0
        case .medium: return 0.23
        case .semibold: return 0.3
        case .bold: return 0.4
        case .heavy: return 0.56
        case .black: return 0.62
        }
    }
}

/// Configuration for a specific font family and styling defaults.
public struct FontConfig: Equatable, Sendable {
    public var family: String
    public var weight: FontWeight
    public var tracking: CGFloat
    public var lineHeight: CGFloat?

    public init(
        family: String,
        weight: FontWeight = .regular,
        tracking: CGFloat = 0,
        lineHeight: CGFloat? = nil
    ) {
        self.family = family
        self.weight = weight
        self.tracking = tracking
        self.lineHeight = lineHeight
    }

    /// Validates that the font family is not empty.
    public func validate(role: FontRole) throws {
        if family.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TypographyValidationError.emptyFontFamily(role)
        }
    }
}

/// Named typographic scale step.
public enum TextStyle: String, Hashable, Sendable, CaseIterable {
    case caption2   // step -3
    case caption    // step -2
    case footnote   // step -1
    case body       // step 0 (baseSize)
    case bodyMedium // step 1
    case subheading // step 2
    case heading4   // step 3
    case heading3   // step 4
    case heading2   // step 5
    case heading1   // step 6
    case display    // step 7

    public var scaleStep: Int {
        switch self {
        case .caption2: return -3
        case .caption: return -2
        case .footnote: return -1
        case .body: return 0
        case .bodyMedium: return 1
        case .subheading: return 2
        case .heading4: return 3
        case .heading3: return 4
        case .heading2: return 5
        case .heading1: return 6
        case .display: return 7
        }
    }
}

/// Typographic scale multiplier ratio.
public enum TypeScale: Equatable, Sendable {
    case majorSecond    // 1.125
    case majorThird     // 1.250
    case perfectFourth  // 1.333
    case augmentedFourth // 1.414
    case custom([CGFloat])
    case customMap([TextStyle: CGFloat])

    public var ratio: CGFloat? {
        switch self {
        case .majorSecond: return 1.125
        case .majorThird: return 1.250
        case .perfectFourth: return 1.333
        case .augmentedFourth: return 1.414
        case .custom, .customMap: return nil
        }
    }
}

/// Complete typography configuration for a theme.
public struct Typography: Equatable, Sendable {
    public var body: FontConfig
    public var heading: FontConfig
    public var mono: FontConfig
    public var display: FontConfig
    public var customRoles: [String: FontConfig]
    public var baseSize: CGFloat
    public var scale: TypeScale

    public init(
        body: FontConfig = .init(family: "Inter", weight: .regular),
        heading: FontConfig = .init(family: "Inter", weight: .semibold),
        mono: FontConfig = .init(family: "JetBrains Mono", weight: .regular),
        display: FontConfig = .init(family: "Inter", weight: .bold),
        customRoles: [String: FontConfig] = [:],
        baseSize: CGFloat = 16,
        scale: TypeScale = .majorThird
    ) {
        self.body = body
        self.heading = heading
        self.mono = mono
        self.display = display
        self.customRoles = customRoles
        self.baseSize = baseSize
        self.scale = scale
    }

    /// Resolves font configuration for a given role.
    public func fontConfig(for role: FontRole) -> FontConfig {
        switch role {
        case .body: return body
        case .heading: return heading
        case .mono: return mono
        case .display: return display
        case .custom(let name):
            return customRoles[name] ?? body
        }
    }

    /// Calculates font size in points for a given style using the configured scale.
    public func fontSize(for style: TextStyle) -> CGFloat {
        switch scale {
        case .customMap(let map):
            if let customSize = map[style] {
                return customSize
            }
            return calculateFromRatio(ratio: 1.250, step: style.scaleStep)

        case .custom(let steps):
            // Map step to index in steps array (assuming index 3 or 4 is body)
            let index = style.scaleStep + 3
            if index >= 0 && index < steps.count {
                return steps[index]
            }
            return calculateFromRatio(ratio: 1.250, step: style.scaleStep)

        case .majorSecond, .majorThird, .perfectFourth, .augmentedFourth:
            let ratio = scale.ratio ?? 1.250
            return calculateFromRatio(ratio: ratio, step: style.scaleStep)
        }
    }

    /// Calculates font size in points for a given style with Dynamic Type scaling and clamp.
    public func fontSize(
        for style: TextStyle,
        contentSizeCategory: ContentSizeCategory = .large,
        dynamicTypeConfig: DynamicTypeConfig? = nil
    ) -> CGFloat {
        let base = fontSize(for: style)
        if contentSizeCategory == .large {
            return base
        }
        let config = dynamicTypeConfig ?? (contentSizeCategory.isAccessibilityCategory ? .accessibility : .standard)
        let clampedScale = config.clamp(contentSizeCategory.scaleFactor)
        let scaledSize = base * clampedScale
        return (scaledSize * 2).rounded() / 2
    }

    /// Calculates scaled line-height for a style and role under Dynamic Type.
    public func scaledLineHeight(
        for style: TextStyle,
        role: FontRole = .body,
        contentSizeCategory: ContentSizeCategory = .large,
        dynamicTypeConfig: DynamicTypeConfig? = nil
    ) -> CGFloat {
        let config = fontConfig(for: role)
        let size = fontSize(for: style, contentSizeCategory: contentSizeCategory, dynamicTypeConfig: dynamicTypeConfig)
        if let customLH = config.lineHeight {
            let ratio = customLH / fontSize(for: style)
            return (size * ratio * 2).rounded() / 2
        }
        let factor: CGFloat = (style == .body || style == .caption || style == .footnote) ? 1.35 : 1.20
        return (size * factor * 2).rounded() / 2
    }

    private func calculateFromRatio(ratio: CGFloat, step: Int) -> CGFloat {
        let size = baseSize * pow(ratio, CGFloat(step))
        return (size * 2).rounded() / 2 // round to nearest 0.5pt
    }

    /// Validates that typography configurations have valid non-empty families and positive base size.
    public func validate() throws {
        if baseSize <= 0 {
            throw TypographyValidationError.invalidBaseSize(baseSize)
        }
        try body.validate(role: .body)
        try heading.validate(role: .heading)
        try mono.validate(role: .mono)
        try display.validate(role: .display)
        for (name, config) in customRoles {
            try config.validate(role: .custom(name))
        }
    }
}

/// Dynamic type scaling configuration with min and max clamping policies.
public struct DynamicTypeConfig: Equatable, Sendable {
    public var minScale: CGFloat
    public var maxScale: CGFloat

    public init(minScale: CGFloat = 0.8, maxScale: CGFloat = 2.0) {
        self.minScale = minScale
        self.maxScale = maxScale
    }

    public static let standard = DynamicTypeConfig(minScale: 0.8, maxScale: 2.0)
    public static let accessibility = DynamicTypeConfig(minScale: 0.8, maxScale: 3.5)

    /// Clamps an incoming Dynamic Type scale factor to the allowed range.
    public func clamp(_ rawScale: CGFloat) -> CGFloat {
        max(minScale, min(maxScale, rawScale))
    }
}

public enum TypographyValidationError: Error, Equatable, Sendable {
    case emptyFontFamily(FontRole)
    case invalidBaseSize(CGFloat)
}
