import Foundation
import CoreGraphics

/// Errors encountered during SVG document parsing.
public enum SVGError: Error, LocalizedError, Sendable, Equatable {
    case xmlParseError(String)
    case securityViolation(String)
    case unsupportedElement(String)

    public var errorDescription: String? {
        switch self {
        case .xmlParseError(let msg): return "XML parse error: \(msg)"
        case .securityViolation(let reason): return "Security violation: \(reason)"
        case .unsupportedElement(let elem): return "Unsupported element: \(elem)"
        }
    }
}

/// Severity level for issues encountered during SVG parsing.
public enum SVGDiagnosticSeverity: String, Sendable, Hashable {
    case warning
    case error
}

/// Diagnostic message emitted when an SVG contains unsupported, malformed, or rejected features.
public struct SVGDiagnostic: Sendable, Hashable, CustomStringConvertible {
    public let message: String
    public let severity: SVGDiagnosticSeverity
    public let line: Int?
    public let column: Int?

    public init(message: String, severity: SVGDiagnosticSeverity = .warning, line: Int? = nil, column: Int? = nil) {
        self.message = message
        self.severity = severity
        self.line = line
        self.column = column
    }

    public var description: String {
        var prefix = "[\(severity.rawValue.uppercased())]"
        if let line {
            prefix += " line \(line)"
            if let column { prefix += ":\(column)" }
        }
        return "\(prefix) \(message)"
    }
}

/// W3C SVG fill rule specification.
public enum SVGFillRule: String, Sendable, Hashable {
    case nonZero = "nonzero"
    case evenOdd = "evenodd"
}

/// A parsed, styleable vector shape primitive within an SVG document.
public struct SVGShape: @unchecked Sendable {
    public var path: CGPath
    public var fillColor: Color?
    public var strokeColor: Color?
    public var strokeWidth: Double
    public var lineCap: CGLineCap
    public var lineJoin: CGLineJoin
    public var fillRule: SVGFillRule
    public var opacity: Double
    public var fillOpacity: Double
    public var strokeOpacity: Double
    public var transform: CGAffineTransform

    public init(
        path: CGPath,
        fillColor: Color? = nil,
        strokeColor: Color? = nil,
        strokeWidth: Double = 0,
        lineCap: CGLineCap = .butt,
        lineJoin: CGLineJoin = .miter,
        fillRule: SVGFillRule = .nonZero,
        opacity: Double = 1.0,
        fillOpacity: Double = 1.0,
        strokeOpacity: Double = 1.0,
        transform: CGAffineTransform = .identity
    ) {
        self.path = path
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.fillRule = fillRule
        self.opacity = opacity
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
        self.transform = transform
    }
}

/// Immutable parsed representation of an SVG asset containing vector shapes and viewport dimensions.
public final class SVGDocument: @unchecked Sendable {
    public let viewBox: CGRect
    public let width: Double?
    public let height: Double?
    public let shapes: [SVGShape]
    public let diagnostics: [SVGDiagnostic]

    public init(
        viewBox: CGRect,
        width: Double? = nil,
        height: Double? = nil,
        shapes: [SVGShape],
        diagnostics: [SVGDiagnostic] = []
    ) {
        self.viewBox = viewBox
        self.width = width
        self.height = height
        self.shapes = shapes
        self.diagnostics = diagnostics
    }

    /// Intrinsic aspect ratio and base size of the document.
    public var naturalSize: CGSize {
        if let width, let height, width > 0, height > 0 {
            return CGSize(width: width, height: height)
        }
        if viewBox.width > 0 && viewBox.height > 0 {
            return CGSize(width: viewBox.width, height: viewBox.height)
        }
        return CGSize(width: 24, height: 24)
    }

    /// Computes the affine transform required to fit the viewBox into target bounds.
    public func transform(into targetBounds: CGRect) -> CGAffineTransform {
        guard viewBox.width > 0, viewBox.height > 0, targetBounds.width > 0, targetBounds.height > 0 else {
            return .identity
        }

        let scaleX = targetBounds.width / viewBox.width
        let scaleY = targetBounds.height / viewBox.height
        let scale = min(scaleX, scaleY)

        let scaledWidth = viewBox.width * scale
        let scaledHeight = viewBox.height * scale

        let offsetX = targetBounds.minX + (targetBounds.width - scaledWidth) / 2.0 - viewBox.minX * scale
        let offsetY = targetBounds.minY + (targetBounds.height - scaledHeight) / 2.0 - viewBox.minY * scale

        return CGAffineTransform(translationX: offsetX, y: offsetY).scaledBy(x: scale, y: scale)
    }
}
