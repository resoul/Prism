import Foundation
import CoreGraphics

/// Safe XML parser translating SVG markup into an immutable `SVGDocument`.
///
/// Security guarantee: Strictly rejects external entities, external resources, CSS stylesheets,
/// `<script>` tags, filters, and text elements, emitting diagnostics while remaining safe from XML attacks.
public final class SVGParser: NSObject, XMLParserDelegate, @unchecked Sendable {

    private struct GroupContext {
        var fillColor: Color?
        var strokeColor: Color?
        var strokeWidth: Double?
        var lineCap: CGLineCap?
        var lineJoin: CGLineJoin?
        var opacity: Double = 1.0
        var fillOpacity: Double = 1.0
        var strokeOpacity: Double = 1.0
        var transform: CGAffineTransform = .identity
    }

    private var viewBox: CGRect = .zero
    private var docWidth: Double? = nil
    private var docHeight: Double? = nil
    private var shapes: [SVGShape] = []
    private var diagnostics: [SVGDiagnostic] = []

    private var groupStack: [GroupContext] = []
    private var parser: XMLParser?

    /// Parses raw SVG UTF-8 string data into an `SVGDocument`. Throws if security violations occur.
    public static func parse(string: String) throws -> SVGDocument {
        guard let data = string.data(using: .utf8) else {
            throw SVGError.xmlParseError("Failed to decode SVG string as UTF-8")
        }
        return try parse(data: data)
    }

    /// Parses raw SVG data into an `SVGDocument`. Throws if security violations occur.
    public static func parse(data: Data) throws -> SVGDocument {
        let instance = SVGParser()
        let doc = instance.execute(data: data)
        for diag in doc.diagnostics {
            if diag.message.starts(with: "Security violation") {
                throw SVGError.securityViolation(diag.message)
            }
        }
        return doc
    }

    private func execute(data: Data) -> SVGDocument {
        let xmlParser = XMLParser(data: data)
        self.parser = xmlParser
        xmlParser.delegate = self
        xmlParser.shouldResolveExternalEntities = false
        xmlParser.shouldProcessNamespaces = false
        xmlParser.shouldReportNamespacePrefixes = false

        groupStack = [GroupContext()]

        let success = xmlParser.parse()
        if !success, let error = xmlParser.parserError {
            diagnostics.append(SVGDiagnostic(
                message: "XML parse error: \(error.localizedDescription)",
                severity: .error,
                line: xmlParser.lineNumber,
                column: xmlParser.columnNumber
            ))
        }

        return SVGDocument(
            viewBox: viewBox,
            width: docWidth,
            height: docHeight,
            shapes: shapes,
            diagnostics: diagnostics
        )
    }

    // MARK: - XMLParserDelegate

    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String] = [:]
    ) {
        let name = elementName.lowercased()

        // 1. Security & Rejected Elements Check
        switch name {
        case "script":
            diagnostics.append(SVGDiagnostic(
                message: "Security violation: <script> tag rejected",
                severity: .error,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
            return

        case "style":
            diagnostics.append(SVGDiagnostic(
                message: "Unsupported element: <style> CSS blocks rejected",
                severity: .warning,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
            return

        case "foreignobject":
            diagnostics.append(SVGDiagnostic(
                message: "Security violation: <foreignObject> rejected",
                severity: .error,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
            return

        case "filter":
            diagnostics.append(SVGDiagnostic(
                message: "Unsupported element: <filter> rejected",
                severity: .warning,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
            return

        case "text", "tspan":
            diagnostics.append(SVGDiagnostic(
                message: "Unsupported element: <\(name)> text elements rejected (use Prism Text primitive)",
                severity: .warning,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
            return

        default:
            break
        }

        // 2. Reject external references in attributes (e.g. href, xlink:href, src)
        for (key, val) in attributes {
            let lowerKey = key.lowercased()
            if (lowerKey == "href" || lowerKey == "xlink:href" || lowerKey == "src") {
                if val.starts(with: "http://") || val.starts(with: "https://") || val.starts(with: "file://") {
                    diagnostics.append(SVGDiagnostic(
                        message: "Security violation: External URI reference in '\(key)' rejected: \(val)",
                        severity: .error,
                        line: parser.lineNumber,
                        column: parser.columnNumber
                    ))
                    return
                }
            }
        }

        // 3. Process supported SVG elements
        switch name {
        case "svg":
            handleSVGElement(attributes)

        case "g":
            pushGroup(attributes)

        case "path":
            handlePath(attributes)

        case "rect":
            handleRect(attributes)

        case "circle":
            handleCircle(attributes)

        case "ellipse":
            handleEllipse(attributes)

        case "line":
            handleLine(attributes)

        case "polyline":
            handlePolyline(attributes, isClosed: false)

        case "polygon":
            handlePolyline(attributes, isClosed: true)

        default:
            diagnostics.append(SVGDiagnostic(
                message: "Ignored unsupported element <\(name)>",
                severity: .warning,
                line: parser.lineNumber,
                column: parser.columnNumber
            ))
        }
    }

    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName.lowercased() == "g" && groupStack.count > 1 {
            groupStack.removeLast()
        }
    }

    // MARK: - Element Handlers

    private func handleSVGElement(_ attributes: [String: String]) {
        if let vb = attributes["viewBox"] ?? attributes["viewbox"] {
            let parts = vb.split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
            if parts.count >= 4 {
                self.viewBox = CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
            }
        }

        if let wStr = attributes["width"], let w = Double(wStr.trimmingCharacters(in: .letters)) {
            self.docWidth = w
        }
        if let hStr = attributes["height"], let h = Double(hStr.trimmingCharacters(in: .letters)) {
            self.docHeight = h
        }

        if viewBox == .zero, let w = docWidth, let h = docHeight, w > 0, h > 0 {
            self.viewBox = CGRect(x: 0, y: 0, width: w, height: h)
        }
    }

    private func pushGroup(_ attributes: [String: String]) {
        guard let parent = groupStack.last else { return }
        var current = parent

        if let fill = parseColor(attributes["fill"]) {
            current.fillColor = fill
        }
        if let stroke = parseColor(attributes["stroke"]) {
            current.strokeColor = stroke
        }
        if let swStr = attributes["stroke-width"] ?? attributes["strokeWidth"], let sw = Double(swStr) {
            current.strokeWidth = sw
        }
        if let cap = parseLineCap(attributes["stroke-linecap"] ?? attributes["strokeLinecap"]) {
            current.lineCap = cap
        }
        if let join = parseLineJoin(attributes["stroke-linejoin"] ?? attributes["strokeLinejoin"]) {
            current.lineJoin = join
        }
        if let opStr = attributes["opacity"], let op = Double(opStr) {
            current.opacity *= op
        }
        if let fOpStr = attributes["fill-opacity"] ?? attributes["fillOpacity"], let fOp = Double(fOpStr) {
            current.fillOpacity *= fOp
        }
        if let sOpStr = attributes["stroke-opacity"] ?? attributes["strokeOpacity"], let sOp = Double(sOpStr) {
            current.strokeOpacity *= sOp
        }

        if let tStr = attributes["transform"] {
            let t = parseTransform(tStr)
            current.transform = current.transform.concatenating(t)
        }

        groupStack.append(current)
    }

    private func handlePath(_ attributes: [String: String]) {
        guard let d = attributes["d"], !d.isEmpty else { return }
        let path = SVGPathParser.parse(d, diagnostics: &diagnostics)
        addShape(path: path, attributes: attributes)
    }

    private func handleRect(_ attributes: [String: String]) {
        let x = Double(attributes["x"] ?? "0") ?? 0
        let y = Double(attributes["y"] ?? "0") ?? 0
        guard let w = Double(attributes["width"] ?? "0"), w > 0,
              let h = Double(attributes["height"] ?? "0"), h > 0 else { return }

        let rx = Double(attributes["rx"] ?? "0") ?? 0
        let ry = Double(attributes["ry"] ?? "0") ?? rx
        let cornerRadius = max(rx, ry)

        let path = CGMutablePath()
        let rect = CGRect(x: x, y: y, width: w, height: h)
        if cornerRadius > 0 {
            path.addRoundedRect(in: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        } else {
            path.addRect(rect)
        }
        addShape(path: path, attributes: attributes)
    }

    private func handleCircle(_ attributes: [String: String]) {
        let cx = Double(attributes["cx"] ?? "0") ?? 0
        let cy = Double(attributes["cy"] ?? "0") ?? 0
        guard let r = Double(attributes["r"] ?? "0"), r > 0 else { return }

        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        addShape(path: path, attributes: attributes)
    }

    private func handleEllipse(_ attributes: [String: String]) {
        let cx = Double(attributes["cx"] ?? "0") ?? 0
        let cy = Double(attributes["cy"] ?? "0") ?? 0
        guard let rx = Double(attributes["rx"] ?? "0"), rx > 0,
              let ry = Double(attributes["ry"] ?? "0"), ry > 0 else { return }

        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        addShape(path: path, attributes: attributes)
    }

    private func handleLine(_ attributes: [String: String]) {
        let x1 = Double(attributes["x1"] ?? "0") ?? 0
        let y1 = Double(attributes["y1"] ?? "0") ?? 0
        let x2 = Double(attributes["x2"] ?? "0") ?? 0
        let y2 = Double(attributes["y2"] ?? "0") ?? 0

        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        addShape(path: path, attributes: attributes, defaultFill: nil, defaultStroke: .black)
    }

    private func handlePolyline(_ attributes: [String: String], isClosed: Bool) {
        guard let pointsStr = attributes["points"] else { return }
        let numbers = pointsStr.split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
        guard numbers.count >= 4 else { return }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: numbers[0], y: numbers[1]))

        var i = 2
        while i + 1 < numbers.count {
            path.addLine(to: CGPoint(x: numbers[i], y: numbers[i + 1]))
            i += 2
        }

        if isClosed {
            path.closeSubpath()
        }

        addShape(path: path, attributes: attributes, defaultFill: isClosed ? .black : nil, defaultStroke: isClosed ? nil : .black)
    }

    // MARK: - Shape Assembly & Attribute Merging

    private func addShape(
        path: CGPath,
        attributes: [String: String],
        defaultFill: Color? = .black,
        defaultStroke: Color? = nil
    ) {
        guard let group = groupStack.last else { return }

        var fill = group.fillColor ?? defaultFill
        if let fillStr = attributes["fill"] {
            fill = parseColor(fillStr)
        }

        var stroke = group.strokeColor ?? defaultStroke
        if let strokeStr = attributes["stroke"] {
            stroke = parseColor(strokeStr)
        }

        var strokeWidth = group.strokeWidth ?? 1.0
        if let swStr = attributes["stroke-width"] ?? attributes["strokeWidth"], let sw = Double(swStr) {
            strokeWidth = sw
        }

        var lineCap = group.lineCap ?? .butt
        if let cap = parseLineCap(attributes["stroke-linecap"] ?? attributes["strokeLinecap"]) {
            lineCap = cap
        }

        var lineJoin = group.lineJoin ?? .miter
        if let join = parseLineJoin(attributes["stroke-linejoin"] ?? attributes["strokeLinejoin"]) {
            lineJoin = join
        }

        var opacity = group.opacity
        if let opStr = attributes["opacity"], let op = Double(opStr) {
            opacity *= op
        }

        var fillOpacity = group.fillOpacity
        if let fOpStr = attributes["fill-opacity"] ?? attributes["fillOpacity"], let fOp = Double(fOpStr) {
            fillOpacity *= fOp
        }

        var strokeOpacity = group.strokeOpacity
        if let sOpStr = attributes["stroke-opacity"] ?? attributes["strokeOpacity"], let sOp = Double(sOpStr) {
            strokeOpacity *= sOp
        }

        var transform = group.transform
        if let tStr = attributes["transform"] {
            let t = parseTransform(tStr)
            transform = transform.concatenating(t)
        }

        let fillRule: SVGFillRule = {
            let ruleStr = attributes["fill-rule"] ?? attributes["fillRule"]
            if ruleStr?.lowercased() == "evenodd" {
                return .evenOdd
            }
            return .nonZero
        }()

        let shape = SVGShape(
            path: path,
            fillColor: fill,
            strokeColor: stroke,
            strokeWidth: strokeWidth,
            lineCap: lineCap,
            lineJoin: lineJoin,
            fillRule: fillRule,
            opacity: opacity,
            fillOpacity: fillOpacity,
            strokeOpacity: strokeOpacity,
            transform: transform
        )

        shapes.append(shape)
    }

    // MARK: - Attribute Parsers

    private func parseColor(_ raw: String?) -> Color? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        if raw == "none" || raw.isEmpty {
            return nil
        }
        if raw == "currentcolor" {
            return Color.black // Resolves at render time via tintColor
        }
        if raw.starts(with: "#") {
            return Color(hex: raw)
        }
        switch raw {
        case "black": return Color.black
        case "white": return Color.white
        case "red": return Color(hex: "#FF0000")
        case "green": return Color(hex: "#008000")
        case "blue": return Color(hex: "#0000FF")
        case "yellow": return Color(hex: "#FFFF00")
        case "gray", "grey": return Color(hex: "#808080")
        default:
            return Color(hex: raw)
        }
    }

    private func parseLineCap(_ raw: String?) -> CGLineCap? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        switch raw {
        case "round": return .round
        case "square": return .square
        default: return .butt
        }
    }

    private func parseLineJoin(_ raw: String?) -> CGLineJoin? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else { return nil }
        switch raw {
        case "round": return .round
        case "bevel": return .bevel
        default: return .miter
        }
    }

    private func parseTransform(_ raw: String) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Simple tokenizer for translate(x, y), scale(sx, sy), rotate(deg)
        if trimmed.starts(with: "translate(") {
            let inner = extractFunctionArgs(from: trimmed, prefix: "translate(")
            let parts = inner.split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
            if parts.count >= 2 {
                transform = transform.translatedBy(x: parts[0], y: parts[1])
            } else if parts.count == 1 {
                transform = transform.translatedBy(x: parts[0], y: 0)
            }
        } else if trimmed.starts(with: "scale(") {
            let inner = extractFunctionArgs(from: trimmed, prefix: "scale(")
            let parts = inner.split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
            if parts.count >= 2 {
                transform = transform.scaledBy(x: parts[0], y: parts[1])
            } else if parts.count == 1 {
                transform = transform.scaledBy(x: parts[0], y: parts[0])
            }
        } else if trimmed.starts(with: "rotate(") {
            let inner = extractFunctionArgs(from: trimmed, prefix: "rotate(")
            if let deg = Double(inner) {
                transform = transform.rotated(by: deg * .pi / 180.0)
            }
        }

        return transform
    }

    private func extractFunctionArgs(from str: String, prefix: String) -> String {
        guard str.starts(with: prefix), let closeIdx = str.firstIndex(of: ")") else { return "" }
        let startIdx = str.index(str.startIndex, offsetBy: prefix.count)
        guard startIdx < closeIdx else { return "" }
        return String(str[startIdx..<closeIdx])
    }
}
