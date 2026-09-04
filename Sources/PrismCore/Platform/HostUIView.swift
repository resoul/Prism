#if canImport(UIKit)
import UIKit

/// Thin UIKit host view embedding a Prism Virtual Render Tree.
/// Provides safe area insets, display scale factor, trait updates, and attaches the root CALayer.
@MainActor
public final class HostUIView: UIView, PrismHost {
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
        engine.mount(in: self.layer)
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
        traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }

    public var scaleFactor: Double {
        #if os(iOS) || os(tvOS)
        let screenScale = window?.screen.scale ?? UIScreen.main.scale
        return Double(screenScale)
        #else
        return 2.0
        #endif
    }

    public var safeAreaDirectionalInsets: DirectionalEdgeInsets {
        DirectionalEdgeInsets(
            top: Double(safeAreaInsets.top),
            leading: Double(safeAreaInsets.left),
            bottom: Double(safeAreaInsets.bottom),
            trailing: Double(safeAreaInsets.right)
        )
    }

    private func updateFromSystem() {
        engine.bounds = bounds
        engine.scaleFactor = scaleFactor
        engine.colorScheme = colorScheme
        engine.safeAreaInsets = safeAreaDirectionalInsets
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let oldBounds = engine.bounds
        updateFromSystem()
        if oldBounds != bounds {
            onBoundsChange?(bounds)
        }
        engine.render()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            updateFromSystem()
            engine.render()
            onMount?()
        } else {
            teardown()
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let newScheme = colorScheme
            engine.colorScheme = newScheme
            onColorSchemeChange?(newScheme)
            engine.render()
        }
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        engine.safeAreaInsets = safeAreaDirectionalInsets
        engine.render()
    }
}
#endif
