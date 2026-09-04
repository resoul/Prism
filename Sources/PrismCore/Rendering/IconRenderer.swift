import Foundation
import QuartzCore
import CoreGraphics
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Dedicated `LayerRenderer` that visualizes vector icons (`CAShapeLayer`) or rasterized symbol bitmaps (`CALayer`).
@MainActor
public final class IconRenderer: LayerRenderer {
    public let elementID: ElementID
    public let rootLayer: CALayer

    private var currentShapeLayers: [CAShapeLayer] = []

    public init(elementID: ElementID) {
        self.elementID = elementID
        let layer = CALayer()
        layer.name = "IconLayer[\(elementID)]"
        layer.masksToBounds = false
        self.rootLayer = layer
    }

    public func update(element: RenderElement, frame: LayoutFrame, context: RenderContext) {
        RenderTransaction.perform(disableActions: context.disableActions) {
            rootLayer.bounds = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            rootLayer.position = CGPoint(
                x: frame.origin.x + frame.width / 2.0,
                y: frame.origin.y + frame.height / 2.0
            )

            let style = element.resolvedStyle
            rootLayer.opacity = Float(style.opacity)
            rootLayer.zPosition = CGFloat(style.zIndex)

            guard case .icon(let source) = element.kind else {
                clearContent()
                return
            }

            // Resolve styling attributes
            let sizeVal: Double = {
                if let sizeStr = element.props.custom["iconSize"], let val = Double(sizeStr) {
                    return val
                }
                return min(frame.width, frame.height) > 0 ? min(frame.width, frame.height) : 20.0
            }()

            let tintColor: Color = {
                if let colorHex = element.props.custom["iconColor"] {
                    return Color.hex(colorHex)
                }
                if let bg = style.background {
                    return bg
                }
                return Color.black
            }()

            let weight: IconWeight = {
                if let wStr = element.props.custom["iconWeight"], let w = IconWeight(rawValue: wStr) {
                    return w
                }
                return .regular
            }()

            let renderingMode: IconRenderingMode = {
                if let mStr = element.props.custom["iconRenderingMode"], let m = IconRenderingMode(rawValue: mStr) {
                    return m
                }
                return .monochrome
            }()

            renderSource(
                source,
                bounds: rootLayer.bounds,
                size: sizeVal,
                tintColor: tintColor,
                weight: weight,
                renderingMode: renderingMode,
                scaleFactor: context.scaleFactor
            )
        }
    }

    public func destroy() {
        clearContent()
        rootLayer.removeFromSuperlayer()
    }

    // MARK: - Content Rendering

    private func clearContent() {
        rootLayer.contents = nil
        for shape in currentShapeLayers {
            shape.removeFromSuperlayer()
        }
        currentShapeLayers.removeAll()
    }

    private func renderSource(
        _ source: IconSource,
        bounds: CGRect,
        size: Double,
        tintColor: Color,
        weight: IconWeight,
        renderingMode: IconRenderingMode,
        scaleFactor: Double
    ) {
        switch source {
        case .sf(let name):
            clearContent()
            if let cgImage = SFSymbolAdapter.renderSymbol(
                name: name,
                pointSize: size,
                weight: weight,
                tintColor: tintColor,
                scaleFactor: scaleFactor
            ) {
                rootLayer.contents = cgImage
                rootLayer.contentsGravity = .resizeAspect
            }

        case .svg(let name, let bundle):
            // Check registry first
            if let registered = IconRegistry.shared.source(for: name), registered != source {
                renderSource(
                    registered,
                    bounds: bounds,
                    size: size,
                    tintColor: tintColor,
                    weight: weight,
                    renderingMode: renderingMode,
                    scaleFactor: scaleFactor
                )
                return
            }

            // Find in bundle
            let targetBundle: Bundle = bundle.flatMap { Bundle(identifier: $0) } ?? .main
            if let url = targetBundle.url(forResource: name, withExtension: "svg") {
                renderSVG(at: url, bounds: bounds, tintColor: tintColor, renderingMode: renderingMode)
            } else {
                clearContent()
            }

        case .svgURL(let url):
            renderSVG(at: url, bounds: bounds, tintColor: tintColor, renderingMode: renderingMode)

        case .path(let path, let viewBox):
            renderPath(path, viewBox: viewBox, bounds: bounds, tintColor: tintColor)

        case .raster(let name, let bundle):
            clearContent()
            if let cgImage = loadRasterImage(name: name, bundle: bundle) {
                rootLayer.contents = cgImage
                rootLayer.contentsGravity = .resizeAspect
            }
        }
    }

    private func renderSVG(
        at url: URL,
        bounds: CGRect,
        tintColor: Color,
        renderingMode: IconRenderingMode
    ) {
        guard let doc = IconCache.shared.document(for: url) else {
            clearContent()
            return
        }

        renderDocument(doc, bounds: bounds, tintColor: tintColor, renderingMode: renderingMode)
    }

    internal func renderDocument(
        _ doc: SVGDocument,
        bounds: CGRect,
        tintColor: Color,
        renderingMode: IconRenderingMode
    ) {
        clearContent()

        let docTransform = doc.transform(into: bounds)
        let scale = sqrt(abs(docTransform.a * docTransform.d))

        for shape in doc.shapes {
            let shapeLayer = CAShapeLayer()
            var combinedTransform = shape.transform.concatenating(docTransform)
            if let transformedPath = shape.path.copy(using: &combinedTransform) {
                shapeLayer.path = transformedPath
            } else {
                shapeLayer.path = shape.path
            }

            shapeLayer.fillRule = shape.fillRule == .evenOdd ? .evenOdd : .nonZero

            switch renderingMode {
            case .monochrome:
                if shape.fillColor != nil {
                    shapeLayer.fillColor = tintColor.cgColor
                } else {
                    shapeLayer.fillColor = nil
                }
                if shape.strokeColor != nil {
                    shapeLayer.strokeColor = tintColor.cgColor
                } else {
                    shapeLayer.strokeColor = nil
                }

            case .multicolor:
                shapeLayer.fillColor = shape.fillColor?.cgColor
                shapeLayer.strokeColor = shape.strokeColor?.cgColor

            case .hierarchical:
                if let fill = shape.fillColor {
                    shapeLayer.fillColor = tintColor.opacity(fill.alpha * CGFloat(shape.fillOpacity)).cgColor
                } else {
                    shapeLayer.fillColor = nil
                }
                if let stroke = shape.strokeColor {
                    shapeLayer.strokeColor = tintColor.opacity(stroke.alpha * CGFloat(shape.strokeOpacity)).cgColor
                } else {
                    shapeLayer.strokeColor = nil
                }
            }

            shapeLayer.lineWidth = CGFloat(shape.strokeWidth) * scale
            shapeLayer.opacity = Float(shape.opacity)

            rootLayer.addSublayer(shapeLayer)
            currentShapeLayers.append(shapeLayer)
        }
    }

    private func renderPath(
        _ path: CGPath,
        viewBox: CGRect,
        bounds: CGRect,
        tintColor: Color
    ) {
        clearContent()

        var transform = aspectFitTransform(from: viewBox, into: bounds)
        let shapeLayer = CAShapeLayer()
        if let transformed = path.copy(using: &transform) {
            shapeLayer.path = transformed
        } else {
            shapeLayer.path = path
        }
        shapeLayer.fillColor = tintColor.cgColor
        rootLayer.addSublayer(shapeLayer)
        currentShapeLayers.append(shapeLayer)
    }

    private func aspectFitTransform(from viewBox: CGRect, into targetRect: CGRect) -> CGAffineTransform {
        guard viewBox.width > 0, viewBox.height > 0, targetRect.width > 0, targetRect.height > 0 else {
            return .identity
        }
        let scaleX = targetRect.width / viewBox.width
        let scaleY = targetRect.height / viewBox.height
        let scale = min(scaleX, scaleY)

        let scaledW = viewBox.width * scale
        let scaledH = viewBox.height * scale
        let tx = targetRect.origin.x + (targetRect.width - scaledW) / 2.0 - viewBox.origin.x * scale
        let ty = targetRect.origin.y + (targetRect.height - scaledH) / 2.0 - viewBox.origin.y * scale

        return CGAffineTransform(translationX: tx, y: ty).scaledBy(x: scale, y: scale)
    }

    private func loadRasterImage(name: String, bundle: String?) -> CGImage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        let bundleToUse = bundle.flatMap { Bundle(identifier: $0) } ?? .main
        if let img = bundleToUse.image(forResource: name) ?? NSImage(named: NSImage.Name(name)) {
            var rect = CGRect(origin: .zero, size: img.size)
            let hints: [NSImageRep.HintKey: Any]? = nil
            return img.cgImage(forProposedRect: &rect, context: nil, hints: hints)
        }
        return nil
        #elseif canImport(UIKit)
        let bundleToUse = bundle.flatMap { Bundle(identifier: $0) }
        return UIImage(named: name, in: bundleToUse, compatibleWith: nil)?.cgImage
        #else
        return nil
        #endif
    }
}
