import Foundation
import QuartzCore

/// Diagnostic utilities for inspecting layer trees, counting layers, and detecting GPU offscreen rendering hazards.
@MainActor
public enum LayerDiagnostics {
    /// Counts total number of layers recursively in the hierarchy.
    public static func totalLayerCount(_ layer: CALayer) -> Int {
        1 + (layer.sublayers?.reduce(0) { $0 + totalLayerCount($1) } ?? 0)
    }

    /// Checks if a layer configuration triggers GPU offscreen rendering passes
    /// (e.g. combining `masksToBounds` with active shadow rendering).
    public static func hasOffscreenRenderingHazard(_ layer: CALayer) -> Bool {
        let hasShadow = layer.shadowOpacity > 0 && layer.shadowColor != nil
        let hasMask = layer.masksToBounds || layer.mask != nil
        return hasShadow && hasMask
    }

    /// Generates a formatted string representing the CALayer tree for assertion in tests and developer diagnostics.
    public static func dumpLayerTree(_ layer: CALayer, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        let layerName = layer.name ?? String(describing: type(of: layer))
        let frameStr = "frame: (\(layer.frame.origin.x), \(layer.frame.origin.y), \(layer.frame.size.width), \(layer.frame.size.height))"
        var line = "\(prefix)\(layerName) [\(frameStr)]"

        if layer.masksToBounds { line += " [clipped]" }
        if layer.opacity < 1.0 { line += " [opacity: \(layer.opacity)]" }
        if layer.cornerRadius > 0 { line += " [radius: \(layer.cornerRadius)]" }
        if layer.zPosition != 0 { line += " [z: \(layer.zPosition)]" }
        if hasOffscreenRenderingHazard(layer) { line += " [⚠️ offscreen-hazard]" }

        if let sublayers = layer.sublayers, !sublayers.isEmpty {
            let childrenStr = sublayers.map { dumpLayerTree($0, indent: indent + 1) }.joined(separator: "\n")
            return "\(line)\n\(childrenStr)"
        }
        return line
    }
}
