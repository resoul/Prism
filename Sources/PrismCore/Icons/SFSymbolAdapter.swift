import Foundation
import CoreGraphics
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Platform-internal bridge creating `CGImage` from system symbols without exposing platform UI types.
enum SFSymbolAdapter {

    @MainActor
    static func renderSymbol(
        name: String,
        pointSize: Double,
        weight: IconWeight = .regular,
        tintColor: Color? = nil,
        scaleFactor: Double = 1.0
    ) -> CGImage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        var config = NSImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: nsWeight(from: weight))
        if let tintColor {
            let nsColor = NSColor(cgColor: tintColor.cgColor) ?? .black
            config = config.applying(NSImage.SymbolConfiguration(paletteColors: [nsColor]))
        }
        guard let baseImage = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            return nil
        }
        let configured = baseImage.withSymbolConfiguration(config) ?? baseImage
        var rect = CGRect(x: 0, y: 0, width: CGFloat(pointSize), height: CGFloat(pointSize))
        return configured.cgImage(forProposedRect: &rect, context: nil, hints: nil)

        #elseif canImport(UIKit)
        var config = UIImage.SymbolConfiguration(pointSize: CGFloat(pointSize), weight: uiWeight(from: weight))
        if let tintColor {
            let uiColor = UIColor(cgColor: tintColor.cgColor)
            config = config.applying(UIImage.SymbolConfiguration(paletteColors: [uiColor]))
        }
        guard let baseImage = UIImage(systemName: name, withConfiguration: config) else {
            return nil
        }
        return baseImage.cgImage
        #else
        return nil
        #endif
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private static func nsWeight(from weight: IconWeight) -> NSFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
    #endif

    #if canImport(UIKit)
    private static func uiWeight(from weight: IconWeight) -> UIImage.SymbolWeight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
    #endif
}
