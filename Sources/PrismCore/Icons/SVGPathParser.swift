import Foundation
import CoreGraphics

/// Fast and robust parser translating SVG path data strings (`d="..."`) into `CGMutablePath`.
public enum SVGPathParser {

    /// Parses an SVG path data string and returns a `CGPath`.
    public static func parse(_ d: String) -> CGPath {
        var diagnostics: [SVGDiagnostic] = []
        return parse(d, diagnostics: &diagnostics)
    }

    /// Parses an SVG path data string and returns a `CGPath`.
    /// Emits non-fatal diagnostics for malformed tokens while recovering gracefully.
    public static func parse(_ d: String, diagnostics: inout [SVGDiagnostic]) -> CGPath {
        let path = CGMutablePath()
        let scanner = SVGScanner(string: d)

        var currentPoint = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastControlPoint: CGPoint? = nil
        var lastCommand: Character? = nil

        while !scanner.isAtEnd {
            scanner.skipSeparators()
            guard !scanner.isAtEnd else { break }

            var cmd: Character
            let peek = scanner.peek()
            if peek.isLetter {
                cmd = scanner.nextCharacter()
            } else if let prev = lastCommand {
                // Repeating coordinates use previous command (M -> L, m -> l)
                if prev == "M" {
                    cmd = "L"
                } else if prev == "m" {
                    cmd = "l"
                } else {
                    cmd = prev
                }
            } else {
                diagnostics.append(SVGDiagnostic(message: "Unexpected character '\(peek)' in path string"))
                scanner.advance()
                continue
            }

            lastCommand = cmd

            switch cmd {
            case "M", "m":
                guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Missing coordinates for \(cmd)"))
                    break
                }
                let pt = cmd == "m" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)
                path.move(to: pt)
                currentPoint = pt
                subpathStart = pt
                lastControlPoint = nil

            case "L", "l":
                guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Missing coordinates for \(cmd)"))
                    break
                }
                let pt = cmd == "l" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)
                path.addLine(to: pt)
                currentPoint = pt
                lastControlPoint = nil

            case "H", "h":
                guard let x = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Missing coordinate for \(cmd)"))
                    break
                }
                let pt = CGPoint(x: cmd == "h" ? currentPoint.x + x : x, y: currentPoint.y)
                path.addLine(to: pt)
                currentPoint = pt
                lastControlPoint = nil

            case "V", "v":
                guard let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Missing coordinate for \(cmd)"))
                    break
                }
                let pt = CGPoint(x: currentPoint.x, y: cmd == "v" ? currentPoint.y + y : y)
                path.addLine(to: pt)
                currentPoint = pt
                lastControlPoint = nil

            case "C", "c":
                guard let x1 = scanner.scanDouble(), let y1 = scanner.scanDouble(),
                      let x2 = scanner.scanDouble(), let y2 = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Incomplete coordinates for cubic bezier \(cmd)"))
                    break
                }
                let cp1 = cmd == "c" ? CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1) : CGPoint(x: x1, y: y1)
                let cp2 = cmd == "c" ? CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2) : CGPoint(x: x2, y: y2)
                let end = cmd == "c" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)

                path.addCurve(to: end, control1: cp1, control2: cp2)
                currentPoint = end
                lastControlPoint = cp2

            case "S", "s":
                guard let x2 = scanner.scanDouble(), let y2 = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Incomplete coordinates for smooth cubic bezier \(cmd)"))
                    break
                }
                let cp1: CGPoint
                if let last = lastControlPoint {
                    cp1 = CGPoint(x: 2 * currentPoint.x - last.x, y: 2 * currentPoint.y - last.y)
                } else {
                    cp1 = currentPoint
                }
                let cp2 = cmd == "s" ? CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2) : CGPoint(x: x2, y: y2)
                let end = cmd == "s" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)

                path.addCurve(to: end, control1: cp1, control2: cp2)
                currentPoint = end
                lastControlPoint = cp2

            case "Q", "q":
                guard let x1 = scanner.scanDouble(), let y1 = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Incomplete coordinates for quadratic bezier \(cmd)"))
                    break
                }
                let cp = cmd == "q" ? CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1) : CGPoint(x: x1, y: y1)
                let end = cmd == "q" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)

                path.addQuadCurve(to: end, control: cp)
                currentPoint = end
                lastControlPoint = cp

            case "T", "t":
                guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Incomplete coordinates for smooth quadratic bezier \(cmd)"))
                    break
                }
                let cp: CGPoint
                if let last = lastControlPoint {
                    cp = CGPoint(x: 2 * currentPoint.x - last.x, y: 2 * currentPoint.y - last.y)
                } else {
                    cp = currentPoint
                }
                let end = cmd == "t" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)

                path.addQuadCurve(to: end, control: cp)
                currentPoint = end
                lastControlPoint = cp

            case "A", "a":
                guard let rx = scanner.scanDouble(), let ry = scanner.scanDouble(),
                      let rot = scanner.scanDouble(),
                      let largeArcFlag = scanner.scanDouble(),
                      let sweepFlag = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() else {
                    diagnostics.append(SVGDiagnostic(message: "Incomplete arc parameters for \(cmd)"))
                    break
                }
                let end = cmd == "a" ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y) : CGPoint(x: x, y: y)

                addArc(
                    to: path,
                    from: currentPoint,
                    toPoint: end,
                    rx: abs(rx),
                    ry: abs(ry),
                    rotation: rot * .pi / 180.0,
                    largeArc: largeArcFlag != 0,
                    sweep: sweepFlag != 0
                )
                currentPoint = end
                lastControlPoint = nil

            case "Z", "z":
                path.closeSubpath()
                currentPoint = subpathStart
                lastControlPoint = nil

            default:
                diagnostics.append(SVGDiagnostic(message: "Unsupported path command '\(cmd)'"))
                lastControlPoint = nil
            }
        }

        return path
    }

    // MARK: - Elliptical Arc to Cubic Curves Conversion

    private static func addArc(
        to path: CGMutablePath,
        from p1: CGPoint,
        toPoint p2: CGPoint,
        rx inRx: Double,
        ry inRy: Double,
        rotation: Double,
        largeArc: Bool,
        sweep: Bool
    ) {
        if p1 == p2 || inRx == 0 || inRy == 0 {
            path.addLine(to: p2)
            return
        }

        var rx = inRx
        var ry = inRy

        let cosAngle = cos(rotation)
        let sinAngle = sin(rotation)

        let dx = (p1.x - p2.x) / 2.0
        let dy = (p1.y - p2.y) / 2.0

        let x1Prime = cosAngle * dx + sinAngle * dy
        let y1Prime = -sinAngle * dx + cosAngle * dy

        let prx = rx * rx
        let pry = ry * ry
        let px1 = x1Prime * x1Prime
        let py1 = y1Prime * y1Prime

        let radiiCheck = px1 / prx + py1 / pry
        if radiiCheck > 1.0 {
            let s = sqrt(radiiCheck)
            rx *= s
            ry *= s
        }

        let sign: Double = (largeArc == sweep) ? -1.0 : 1.0
        let numerator = max(0, (rx * rx * ry * ry) - (rx * rx * py1) - (ry * ry * px1))
        let denominator = (rx * rx * py1) + (ry * ry * px1)
        let coef = sign * sqrt(numerator / max(1e-9, denominator))

        let cxPrime = coef * ((rx * y1Prime) / ry)
        let cyPrime = coef * -((ry * x1Prime) / rx)

        let cx = cosAngle * cxPrime - sinAngle * cyPrime + (p1.x + p2.x) / 2.0
        let cy = sinAngle * cxPrime + cosAngle * cyPrime + (p1.y + p2.y) / 2.0

        let ux = (x1Prime - cxPrime) / rx
        let uy = (y1Prime - cyPrime) / ry
        let vx = (-x1Prime - cxPrime) / rx
        let vy = (-y1Prime - cyPrime) / ry

        let startAngle = atan2(uy, ux)
        var deltaAngle = atan2(vy, vx) - startAngle

        if !sweep && deltaAngle > 0 {
            deltaAngle -= 2 * .pi
        } else if sweep && deltaAngle < 0 {
            deltaAngle += 2 * .pi
        }

        // Approximate arc segment with cubic beziers (<= 90 deg per segment)
        let segments = max(1, Int(ceil(abs(deltaAngle) / (.pi / 2.0))))
        let step = deltaAngle / Double(segments)

        for i in 0..<segments {
            let theta1 = startAngle + Double(i) * step
            let theta2 = theta1 + step

            let alpha = sin(step) * (sqrt(4.0 + 3.0 * tan(step / 2.0) * tan(step / 2.0)) - 1.0) / 3.0

            let cosTheta1 = cos(theta1)
            let sinTheta1 = sin(theta1)
            let cosTheta2 = cos(theta2)
            let sinTheta2 = sin(theta2)

            let p1x = rx * cosTheta1
            let p1y = ry * sinTheta1
            let p2x = rx * cosTheta2
            let p2y = ry * sinTheta2

            let q1x = p1x - alpha * rx * sinTheta1
            let q1y = p1y + alpha * ry * cosTheta1
            let q2x = p2x + alpha * rx * sinTheta2
            let q2y = p2y - alpha * ry * cosTheta2

            func rotateAndTranslate(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(
                    x: cosAngle * x - sinAngle * y + cx,
                    y: sinAngle * x + cosAngle * y + cy
                )
            }

            let cp1 = rotateAndTranslate(q1x, q1y)
            let cp2 = rotateAndTranslate(q2x, q2y)
            let endPt = rotateAndTranslate(p2x, p2y)

            path.addCurve(to: endPt, control1: cp1, control2: cp2)
        }
    }
}

// MARK: - Character Scanner

private final class SVGScanner {
    private let chars: [Character]
    private var index: Int = 0

    init(string: String) {
        self.chars = Array(string)
    }

    var isAtEnd: Bool {
        index >= chars.count
    }

    func peek() -> Character {
        guard index < chars.count else { return "\0" }
        return chars[index]
    }

    func nextCharacter() -> Character {
        let ch = chars[index]
        index += 1
        return ch
    }

    func advance() {
        if index < chars.count {
            index += 1
        }
    }

    func skipSeparators() {
        while index < chars.count {
            let ch = chars[index]
            if ch.isWhitespace || ch == "," {
                index += 1
            } else {
                break
            }
        }
    }

    func scanDouble() -> Double? {
        skipSeparators()
        guard index < chars.count else { return nil }

        let start = index
        var hasDigits = false

        if chars[index] == "+" || chars[index] == "-" {
            index += 1
        }

        while index < chars.count && chars[index].isNumber {
            hasDigits = true
            index += 1
        }

        if index < chars.count && chars[index] == "." {
            index += 1
            while index < chars.count && chars[index].isNumber {
                hasDigits = true
                index += 1
            }
        }

        if hasDigits && index < chars.count && (chars[index] == "e" || chars[index] == "E") {
            let expStart = index
            index += 1
            if index < chars.count && (chars[index] == "+" || chars[index] == "-") {
                index += 1
            }
            var hasExpDigits = false
            while index < chars.count && chars[index].isNumber {
                hasExpDigits = true
                index += 1
            }
            if !hasExpDigits {
                index = expStart
            }
        }

        guard hasDigits else {
            index = start
            return nil
        }

        let substr = String(chars[start..<index])
        return Double(substr)
    }
}
