import Foundation

/// Unified resolver mapping SizeValue and min/max constraints against parent DimensionConstraints.
public enum ConstraintResolver {
    /// Resolves a 1D dimension given layout style, parent constraint, and intrinsic content measure.
    ///
    /// - Parameters:
    ///   - sizeValue: Sizing behavior specified in LayoutStyle (.fixed, .fraction, .intrinsic, .fill, .range).
    ///   - constraint: Available space offered by the parent (.unspecified, .atMost, .exactly).
    ///   - intrinsic: Intrinsic dimension measured from content (e.g. text bounds or shape natural size).
    ///   - minBound: Optional explicit minimum bound.
    ///   - maxBound: Optional explicit maximum bound.
    /// - Returns: Finite, non-negative dimension in points.
    public static func resolve(
        sizeValue: SizeValue,
        constraint: DimensionConstraint,
        intrinsic: Double = 0,
        minBound: Double? = nil,
        maxBound: Double? = nil
    ) -> Double {
        let safeIntrinsic = intrinsic.isFinite ? max(0, intrinsic) : 0

        // 1. Determine base target dimension
        var base: Double

        switch sizeValue {
        case .fixed(let v):
            base = v.isFinite ? max(0, v) : 0

        case .fraction(let fraction):
            let safeFraction = fraction.isFinite ? max(0, fraction) : 0
            if let available = constraint.maxAvailable {
                base = available * safeFraction
            } else {
                base = safeIntrinsic
            }

        case .intrinsic:
            base = safeIntrinsic

        case .fill:
            if let available = constraint.maxAvailable {
                base = available
            } else {
                base = safeIntrinsic
            }

        case .range:
            base = safeIntrinsic
        }

        // 2. Extract effective min and max bounds
        var effectiveMin: Double = 0
        if let minBound, minBound.isFinite {
            effectiveMin = max(0, minBound)
        }

        var effectiveMax: Double? = nil
        if let maxBound, maxBound.isFinite {
            effectiveMax = max(0, maxBound)
        }

        // Merge range bounds if specified on SizeValue
        if case .range(let rangeMin, let rangeMax) = sizeValue {
            if let rangeMin, rangeMin.isFinite {
                effectiveMin = max(effectiveMin, max(0, rangeMin))
            }
            if let rangeMax, rangeMax.isFinite {
                let safeMax = max(0, rangeMax)
                effectiveMax = effectiveMax.map { min($0, safeMax) } ?? safeMax
            }
        }

        // 3. Min/Max Clamping & Conflict Resolution:
        // Rule: `min` takes precedence over `max` to ensure minimum touch targets and legibility.
        var clamped = base

        if let maxVal = effectiveMax {
            if effectiveMin > maxVal {
                // Conflicting constraints: min wins deterministically
                clamped = effectiveMin
            } else {
                clamped = min(maxVal, max(effectiveMin, base))
            }
        } else {
            clamped = max(effectiveMin, base)
        }

        // 4. Respect parent exact/atMost constraint when applicable
        switch constraint {
        case .unspecified:
            break

        case .atMost(let available):
            if clamped > available && effectiveMin <= available {
                clamped = available
            }

        case .exactly(let available):
            if sizeValue == .fill {
                clamped = available
            } else if clamped > available && effectiveMin <= available {
                clamped = available
            }
        }

        // 5. Final sanity check: finite and non-negative
        guard clamped.isFinite else { return 0 }
        return max(0, clamped)
    }

    /// Resolves 2D size given layout style, 2D parent constraint, and intrinsic 2D content measure.
    public static func resolveSize(
        style: LayoutStyle,
        constraint: SizeConstraint,
        intrinsic: MeasuredSize
    ) -> MeasuredSize {
        let width = resolve(
            sizeValue: style.width,
            constraint: constraint.width,
            intrinsic: intrinsic.width,
            minBound: style.minWidth,
            maxBound: style.maxWidth
        )

        let height = resolve(
            sizeValue: style.height,
            constraint: constraint.height,
            intrinsic: intrinsic.height,
            minBound: style.minHeight,
            maxBound: style.maxHeight
        )

        // Handle aspect ratio constraint if specified
        if let ratio = style.aspectRatio, ratio > 0 {
            if style.width != .intrinsic && style.height == .intrinsic {
                let resolvedHeight = width / ratio
                return MeasuredSize(width: width, height: resolvedHeight)
            } else if style.height != .intrinsic && style.width == .intrinsic {
                let resolvedWidth = height * ratio
                return MeasuredSize(width: resolvedWidth, height: height)
            }
        }

        return MeasuredSize(width: width, height: height)
    }
}
