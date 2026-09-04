import Foundation
import Metal
import QuartzCore
import simd
import PrismLogging

/// LayerRenderer implementation that composites Metal-rendered visual effects
/// (SDF rounded rect, glassmorphism, mesh gradient) with standard CALayers,
/// or falls back gracefully to pure CALayer representations when Metal is unavailable.
@MainActor
public final class MetalEffectRenderer: LayerRenderer {
    public let elementID: ElementID
    public let rootLayer: CALayer

    private var metalLayerWrapper: MetalLayer?
    private var fallbackGradientLayer: CAGradientLayer?
    private let context: MetalDeviceContext
    private var isDestroyed = false

    public init(elementID: ElementID, context: MetalDeviceContext = .shared) {
        self.elementID = elementID
        self.context = context
        self.rootLayer = CALayer()
        self.rootLayer.masksToBounds = true
    }

    public func update(element: RenderElement, frame: LayoutFrame, context renderContext: RenderContext) {
        guard !isDestroyed else { return }

        // Root layer geometry
        rootLayer.frame = frame.rect
        let scale = renderContext.scaleFactor

        let style = ResolvedStyle.resolve(from: element.modifiers)

        // Determine if Metal can be used
        let metalSupported = context.isSupported
        if metalSupported {
            context.ensurePipelinesSync()
        }

        if metalSupported, let pipelines = context.pipelines, let device = context.device, let queue = context.commandQueue {
            // Metal rendering path
            renderMetal(element: element, frame: frame, scale: scale, style: style, pipelines: pipelines, device: device, queue: queue)
        } else {
            // Graceful CALayer fallback path
            renderFallback(element: element, frame: frame, style: style)
        }
    }

    // MARK: - Metal Render Path

    private func renderMetal(
        element: RenderElement,
        frame: LayoutFrame,
        scale: CGFloat,
        style: ResolvedStyle,
        pipelines: MetalPipelines,
        device: MTLDevice,
        queue: MTLCommandQueue
    ) {
        // Clean up fallback layers if previously created
        fallbackGradientLayer?.removeFromSuperlayer()
        fallbackGradientLayer = nil

        let wrapper: MetalLayer
        if let existing = metalLayerWrapper {
            wrapper = existing
        } else {
            wrapper = MetalLayer(context: context)
            metalLayerWrapper = wrapper
            rootLayer.addSublayer(wrapper.metalLayer)
        }

        wrapper.updateFrame(CGRect(x: 0, y: 0, width: frame.width, height: frame.height), contentsScale: scale)


        guard let drawable = wrapper.nextDrawable() else {
            // Drawable unavailable (e.g. 0 size), fallback
            renderFallback(element: element, frame: frame, style: style)
            return
        }

        let renderPassDesc = MTLRenderPassDescriptor()
        renderPassDesc.colorAttachments[0].texture = drawable.texture
        renderPassDesc.colorAttachments[0].loadAction = .clear
        renderPassDesc.colorAttachments[0].storeAction = .store
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else {
            return
        }

        let startTime = CACurrentMediaTime()

        if let sdf = style.sdfRoundedRect {
            // Render SDF Rounded Rect
            encoder.setRenderPipelineState(pipelines.sdfRectPipeline)

            let fillColor = sdf.fill ?? style.background ?? .clear
            var uniforms = SDFRectUniforms(
                size: SIMD2<Float>(Float(frame.size.width), Float(frame.size.height)),
                cornerRadius: Float(sdf.cornerRadius),
                borderWidth: Float(sdf.borderWidth),
                fillColor: SIMD4<Float>(Float(fillColor.red), Float(fillColor.green), Float(fillColor.blue), Float(fillColor.alpha)),
                borderColor: SIMD4<Float>(Float(sdf.borderColor.red), Float(sdf.borderColor.green), Float(sdf.borderColor.blue), Float(sdf.borderColor.alpha))
            )
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<SDFRectUniforms>.stride, index: 0)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SDFRectUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        } else if let glass = style.glassmorphism {
            // Render Glassmorphism
            encoder.setRenderPipelineState(pipelines.glassPipeline)

            var uniforms = GlassUniforms(
                blurRadius: Float(glass.blurRadius),
                saturation: Float(glass.saturation),
                tintColor: SIMD4<Float>(Float(glass.tint.red), Float(glass.tint.green), Float(glass.tint.blue), Float(glass.tint.alpha))
            )
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<GlassUniforms>.stride, index: 0)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GlassUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        } else if let mesh = style.meshGradient {
            // Render Mesh Gradient
            encoder.setRenderPipelineState(pipelines.meshGradientPipeline)

            var uniforms = MeshGradientUniforms(
                width: Int32(mesh.width),
                height: Int32(mesh.height),
                pointCount: Int32(mesh.points.count)
            )
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MeshGradientUniforms>.stride, index: 0)

            var points = mesh.points.map { pt in
                MetalMeshPoint(
                    pos: SIMD2<Float>(Float(pt.x), Float(pt.y)),
                    color: SIMD4<Float>(Float(pt.color.red), Float(pt.color.green), Float(pt.color.blue), Float(pt.color.alpha))
                )
            }
            encoder.setFragmentBytes(&points, length: MemoryLayout<MetalMeshPoint>.stride * points.count, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()

        let elapsedMs = (CACurrentMediaTime() - startTime) * 1000.0
        MetalFrameBudget.recordFrameDuration(milliseconds: elapsedMs, effect: "MetalEffectRenderer")
    }

    // MARK: - Graceful CALayer Fallback Path

    private func renderFallback(element: RenderElement, frame: LayoutFrame, style: ResolvedStyle) {
        // Remove metal layer if fallback is engaged
        metalLayerWrapper?.purgeResources()
        metalLayerWrapper = nil

        if let sdf = style.sdfRoundedRect {
            rootLayer.cornerRadius = CGFloat(sdf.cornerRadius)
            rootLayer.borderWidth = CGFloat(sdf.borderWidth)
            rootLayer.borderColor = sdf.borderColor.cgColor
            if let fill = sdf.fill {
                rootLayer.backgroundColor = fill.cgColor
            } else if let bg = style.background {
                rootLayer.backgroundColor = bg.cgColor
            }
        } else if let glass = style.glassmorphism {
            // Frosted glass fallback: tinted semi-transparent background
            rootLayer.backgroundColor = glass.tint.cgColor
            rootLayer.opacity = Float(style.opacity)
            rootLayer.cornerRadius = 12.0
        } else if let mesh = style.meshGradient {
            // Mesh gradient fallback: multi-stop linear gradient
            let gradient = fallbackGradientLayer ?? CAGradientLayer()
            if fallbackGradientLayer == nil {
                fallbackGradientLayer = gradient
                rootLayer.insertSublayer(gradient, at: 0)
            }
            gradient.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)

            // Sample corner colors from grid
            let c0 = mesh[0, 0].color.cgColor
            let c1 = mesh[mesh.width - 1, 0].color.cgColor
            let c2 = mesh[0, mesh.height - 1].color.cgColor
            let c3 = mesh[mesh.width - 1, mesh.height - 1].color.cgColor
            gradient.colors = [c0, c1, c2, c3]
        }
    }

    public func destroy() {
        guard !isDestroyed else { return }
        isDestroyed = true
        metalLayerWrapper?.purgeResources()
        metalLayerWrapper = nil
        fallbackGradientLayer?.removeFromSuperlayer()
        fallbackGradientLayer = nil
        rootLayer.removeFromSuperlayer()
    }
}
