#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/// Thin AppKit host view embedding a Prism Virtual Render Tree.
/// Backed by a CALayer and forwards frame, backing scale factor, and appearance changes.
@MainActor
public final class HostNSView: NSView, PrismHost {
    public let engine: PrismHostEngine

    public var isInspectorOverlayEnabled: Bool {
        get { engine.isInspectorOverlayEnabled }
        set { engine.isInspectorOverlayEnabled = newValue }
    }

    public var onMount: (() -> Void)?
    public var onBoundsChange: ((CGRect) -> Void)?
    public var onColorSchemeChange: ((ColorScheme) -> Void)?
    public var onTeardown: (() -> Void)?

    public init(element: RenderElement) {
        self.engine = PrismHostEngine(rootElement: element)
        super.init(frame: .zero)
        setupHost()
    }

    public required init?(coder: NSCoder) {
        self.engine = PrismHostEngine(rootElement: RenderElement(id: ElementID(typeName: "Empty"), kind: .empty))
        super.init(coder: coder)
        setupHost()
    }

    private func setupHost() {
        self.wantsLayer = true
        guard let layer = self.layer else { return }
        engine.mount(in: layer)
        updateFromSystem()
    }

    public func setRootElement(_ element: RenderElement) {
        engine.rootElement = element
    }

    public func render() {
        updateFromSystem()
        engine.render()
    }

    public func teardown() {
        onTeardown?()
        engine.teardown()
    }

    public var colorScheme: ColorScheme {
        let match = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return match == .darkAqua ? .dark : .light
    }

    public var scaleFactor: Double {
        Double(window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0)
    }

    public var safeAreaDirectionalInsets: DirectionalEdgeInsets {
        if #available(macOS 11.0, *) {
            return DirectionalEdgeInsets(
                top: Double(safeAreaInsets.top),
                leading: Double(safeAreaInsets.left),
                bottom: Double(safeAreaInsets.bottom),
                trailing: Double(safeAreaInsets.right)
            )
        }
        return .zero
    }

    private func updateFromSystem() {
        engine.bounds = bounds
        engine.scaleFactor = scaleFactor
        engine.colorScheme = colorScheme
        engine.safeAreaInsets = safeAreaDirectionalInsets
    }

    public override func layout() {
        super.layout()
        let oldBounds = engine.bounds
        updateFromSystem()
        if oldBounds != bounds {
            onBoundsChange?(bounds)
        }
        engine.render()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        let oldBounds = engine.bounds
        super.setFrameSize(newSize)
        updateFromSystem()
        if oldBounds != bounds {
            onBoundsChange?(bounds)
        }
        engine.render()
    }


    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            updateFromSystem()
            engine.render()
            onMount?()
        } else {
            teardown()
        }
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        let newScheme = colorScheme
        engine.colorScheme = newScheme
        onColorSchemeChange?(newScheme)
        engine.render()
    }

    public override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        engine.scaleFactor = scaleFactor
        engine.render()
    }
}
#endif
