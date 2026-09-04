import Foundation
import Metal
import QuartzCore
import simd

// MARK: - Uniform Structures (matching MSL layouts)

public struct SDFRectUniforms: Equatable, Sendable {
    public var size: SIMD2<Float>
    public var cornerRadius: Float
    public var borderWidth: Float
    public var fillColor: SIMD4<Float>
    public var borderColor: SIMD4<Float>

    public init(
        size: SIMD2<Float>,
        cornerRadius: Float,
        borderWidth: Float,
        fillColor: SIMD4<Float>,
        borderColor: SIMD4<Float>
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.fillColor = fillColor
        self.borderColor = borderColor
    }
}

public struct GlassUniforms: Equatable, Sendable {
    public var blurRadius: Float
    public var saturation: Float
    public var padding: SIMD2<Float>
    public var tintColor: SIMD4<Float>

    public init(blurRadius: Float, saturation: Float, tintColor: SIMD4<Float>) {
        self.blurRadius = blurRadius
        self.saturation = saturation
        self.padding = .zero
        self.tintColor = tintColor
    }
}

public struct MetalMeshPoint: Equatable, Sendable {
    public var pos: SIMD2<Float>
    public var padding: SIMD2<Float>
    public var color: SIMD4<Float>

    public init(pos: SIMD2<Float>, color: SIMD4<Float>) {
        self.pos = pos
        self.padding = .zero
        self.color = color
    }
}

public struct MeshGradientUniforms: Equatable, Sendable {
    public var width: Int32
    public var height: Int32
    public var pointCount: Int32
    public var padding: Int32

    public init(width: Int32, height: Int32, pointCount: Int32) {
        self.width = width
        self.height = height
        self.pointCount = pointCount
        self.padding = 0
    }
}

// MARK: - Pipeline State Manager

public final class MetalPipelines: @unchecked Sendable {
    public let sdfRectPipeline: MTLRenderPipelineState
    public let glassPipeline: MTLRenderPipelineState
    public let meshGradientPipeline: MTLRenderPipelineState

    public init(
        sdfRectPipeline: MTLRenderPipelineState,
        glassPipeline: MTLRenderPipelineState,
        meshGradientPipeline: MTLRenderPipelineState
    ) {
        self.sdfRectPipeline = sdfRectPipeline
        self.glassPipeline = glassPipeline
        self.meshGradientPipeline = meshGradientPipeline
    }

    /// Compiles all shaders from the MSL source into cached pipeline states.
    public static func build(device: MTLDevice) throws -> MetalPipelines {
        let options = MTLCompileOptions()
        options.fastMathEnabled = true

        let library = try device.makeLibrary(source: MetalShaders.source, options: options)

        guard let quadVertex = library.makeFunction(name: "quad_vertex") else {
            throw MetalPipelineError.functionNotFound("quad_vertex")
        }

        // 1. SDF Rect Pipeline
        guard let sdfFragment = library.makeFunction(name: "sdf_rounded_rect_fragment") else {
            throw MetalPipelineError.functionNotFound("sdf_rounded_rect_fragment")
        }
        let sdfDesc = MTLRenderPipelineDescriptor()
        sdfDesc.vertexFunction = quadVertex
        sdfDesc.fragmentFunction = sdfFragment
        sdfDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        sdfDesc.colorAttachments[0].isBlendingEnabled = true
        sdfDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        sdfDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        sdfDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        sdfDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        let sdfPipeline = try device.makeRenderPipelineState(descriptor: sdfDesc)

        // 2. Glass Pipeline
        guard let glassFragment = library.makeFunction(name: "glass_fragment") else {
            throw MetalPipelineError.functionNotFound("glass_fragment")
        }
        let glassDesc = MTLRenderPipelineDescriptor()
        glassDesc.vertexFunction = quadVertex
        glassDesc.fragmentFunction = glassFragment
        glassDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        glassDesc.colorAttachments[0].isBlendingEnabled = true
        glassDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        glassDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        glassDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        glassDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        let glassPipeline = try device.makeRenderPipelineState(descriptor: glassDesc)

        // 3. Mesh Gradient Pipeline
        guard let meshFragment = library.makeFunction(name: "mesh_gradient_fragment") else {
            throw MetalPipelineError.functionNotFound("mesh_gradient_fragment")
        }
        let meshDesc = MTLRenderPipelineDescriptor()
        meshDesc.vertexFunction = quadVertex
        meshDesc.fragmentFunction = meshFragment
        meshDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        meshDesc.colorAttachments[0].isBlendingEnabled = true
        meshDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        meshDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        meshDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        meshDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        let meshPipeline = try device.makeRenderPipelineState(descriptor: meshDesc)

        return MetalPipelines(
            sdfRectPipeline: sdfPipeline,
            glassPipeline: glassPipeline,
            meshGradientPipeline: meshPipeline
        )
    }
}

public enum MetalPipelineError: Error, LocalizedError {
    case functionNotFound(String)
    case deviceUnavailable

    public var errorDescription: String? {
        switch self {
        case .functionNotFound(let name):
            return "Metal shader function '\(name)' not found in library."
        case .deviceUnavailable:
            return "Metal device is unavailable."
        }
    }
}
