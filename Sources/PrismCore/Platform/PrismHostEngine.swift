import Foundation
import QuartzCore

/// Platform-agnostic host engine driving layout passes, CALayer tree synchronization,
/// and debug inspector overlays for a mounted Prism component hierarchy.
@MainActor
public final class PrismHostEngine {
    public var rootElement: RenderElement {
        didSet {
            render()
        }
    }

    public var scaleFactor: Double = 2.0 {
        didSet {
            if oldValue != scaleFactor { render() }
        }
    }

    public var colorScheme: ColorScheme = .light {
        didSet {
            if oldValue != colorScheme { render() }
        }
    }

    public var safeAreaInsets: DirectionalEdgeInsets = .zero {
        didSet {
            if oldValue != safeAreaInsets { render() }
        }
    }

    public var bounds: CGRect = .zero {
        didSet {
            if oldValue != bounds { render() }
        }
    }

    public var isInspectorOverlayEnabled: Bool = false {
        didSet {
            updateInspectorOverlay()
        }
    }

    public private(set) var rootRenderer: ContainerRenderer
    public private(set) var rootLayoutNode: LayoutNode?
    public private(set) weak var hostLayer: CALayer?
    public private(set) var inspectorLayer: CALayer = CALayer()

    public init(rootElement: RenderElement) {
        let normalized = rootElement.normalized()
        self.rootElement = normalized
        self.rootRenderer = ContainerRenderer(elementID: normalized.id)
        self.inspectorLayer.name = "PrismInspectorOverlay"
    }

    /// Attaches the Prism root CALayer into the host platform view's backing layer.
    public func mount(in containerLayer: CALayer) {
        self.hostLayer = containerLayer
        if rootRenderer.rootLayer.superlayer != containerLayer {
            containerLayer.addSublayer(rootRenderer.rootLayer)
        }
        render()
    }

    /// Executes the two-pass layout calculation (measure -> layout) and updates CALayer renderers.
    public func render() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let normalized = rootElement.normalized()
        let layoutNode = LayoutTreeBuilder.build(from: normalized)
        self.rootLayoutNode = layoutNode

        let contentWidth = max(0, bounds.width - safeAreaInsets.leading - safeAreaInsets.trailing)
        let contentHeight = max(0, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom)

        let constraint = SizeConstraint(
            width: .exactly(contentWidth),
            height: .atMost(contentHeight)
        )
        layoutNode.measure(constraint: constraint)

        let rootFrame = LayoutFrame(
            x: safeAreaInsets.leading,
            y: safeAreaInsets.top,
            width: contentWidth,
            height: contentHeight
        )

        let roundingPolicy = PixelRoundingPolicy(scaleFactor: scaleFactor)
        layoutNode.layout(frame: rootFrame, roundingPolicy: roundingPolicy)

        let renderContext = RenderContext(
            scaleFactor: scaleFactor,
            colorScheme: colorScheme,
            disableActions: true
        )

        rootRenderer.update(element: normalized, frame: rootFrame, context: renderContext)
        syncSubtree(containerRenderer: rootRenderer, element: normalized, layoutNode: layoutNode, context: renderContext)

        updateInspectorOverlay()
    }

    private func syncSubtree(
        containerRenderer: ContainerRenderer,
        element: RenderElement,
        layoutNode: LayoutNode,
        context: RenderContext
    ) {
        var childPairs: [(element: RenderElement, frame: LayoutFrame)] = []
        for (childElement, childLayout) in zip(element.children, layoutNode.children) {
            let frame = childLayout.layoutFrame ?? .zero
            childPairs.append((childElement, frame))
        }

        containerRenderer.updateChildren(children: childPairs, context: context)

        for (childElement, childLayout) in zip(element.children, layoutNode.children) {
            if let childContainer = containerRenderer.childRenderers[childElement.id] as? ContainerRenderer {
                syncSubtree(
                    containerRenderer: childContainer,
                    element: childElement,
                    layoutNode: childLayout,
                    context: context
                )
            }
        }
    }

    /// Detaches layers and destroys renderers cleanly.
    public func teardown() {
        inspectorLayer.removeFromSuperlayer()
        inspectorLayer.sublayers?.removeAll()
        rootRenderer.destroy()
        hostLayer = nil
    }

    /// Returns a structured diagnostic dump of the host state, element tree, layout trace, and layer tree.
    public func dumpDiagnostics() -> String {
        var output = "=== Prism Host Diagnostics ===\n"
        output += "Bounds: \(bounds)\n"
        output += "Scale: \(scaleFactor), Scheme: \(colorScheme), SafeArea: \(safeAreaInsets)\n"
        output += "--- Element Tree ---\n"
        output += rootElement.dumpTree() + "\n"
        if let node = rootLayoutNode {
            output += "--- Layout Trace ---\n"
            output += node.dumpTrace() + "\n"
        }
        output += "--- CALayer Tree ---\n"
        output += LayerDiagnostics.dumpLayerTree(rootRenderer.rootLayer) + "\n"
        output += "Total Layers: \(LayerDiagnostics.totalLayerCount(rootRenderer.rootLayer))\n"
        return output
    }

    private func updateInspectorOverlay() {
        guard isInspectorOverlayEnabled, let host = hostLayer else {
            inspectorLayer.removeFromSuperlayer()
            inspectorLayer.sublayers?.removeAll()
            return
        }

        inspectorLayer.frame = host.bounds
        if inspectorLayer.superlayer == nil {
            host.addSublayer(inspectorLayer)
        }

        inspectorLayer.sublayers?.removeAll()
        if let rootNode = rootLayoutNode {
            addDebugOutlines(node: rootNode, parentOrigin: .zero)
        }
    }

    private func addDebugOutlines(node: LayoutNode, parentOrigin: CGPoint) {
        guard let frame = node.layoutFrame else { return }

        let outline = CALayer()
        let globalOrigin = CGPoint(x: parentOrigin.x + frame.origin.x, y: parentOrigin.y + frame.origin.y)
        outline.frame = CGRect(x: globalOrigin.x, y: globalOrigin.y, width: frame.width, height: frame.height)
        outline.borderWidth = 1.0 / CGFloat(scaleFactor)
        outline.borderColor = CGColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.6)
        inspectorLayer.addSublayer(outline)

        for child in node.children {
            addDebugOutlines(node: child, parentOrigin: globalOrigin)
        }
    }
}
