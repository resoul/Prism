import Foundation

/// Metal Shading Language source code strings for Prism visual effects.
public enum MetalShaders {
    /// MSL source code containing vertex and fragment shaders for SDF rounded rects, glassmorphism, and mesh gradients.
    public static let source = """
    #include <metal_stdlib>
    using namespace metal;

    // MARK: - Vertex Input/Output

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 uv [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    // Shared simple quad vertex shader
    vertex VertexOut quad_vertex(uint vertexID [[vertex_id]]) {
        // Standard full-screen quad from 4 vertices (triangle strip: 0, 1, 2, 3)
        // 0: (-1, -1), 1: (1, -1), 2: (-1, 1), 3: (1, 1)
        float2 positions[4] = {
            float2(-1.0, -1.0),
            float2( 1.0, -1.0),
            float2(-1.0,  1.0),
            float2( 1.0,  1.0)
        };
        float2 uvs[4] = {
            float2(0.0, 1.0),
            float2(1.0, 1.0),
            float2(0.0, 0.0),
            float2(1.0, 0.0)
        };

        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = uvs[vertexID];
        return out;
    }

    // MARK: - SDF Rounded Rectangle Shader

    struct SDFRectUniforms {
        float2 size;          // width, height in points
        float cornerRadius;   // radius in points
        float borderWidth;    // border width in points
        float4 fillColor;     // RGBA
        float4 borderColor;   // RGBA
    };

    // Signed distance to rounded box centered at origin
    float sdRoundBox(float2 p, float2 b, float r) {
        float2 q = abs(p) - b + float2(r);
        return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    }

    fragment float4 sdf_rounded_rect_fragment(
        VertexOut in [[stage_in]],
        constant SDFRectUniforms &u [[buffer(0)]]
    ) {
        // Pixel position mapped to center origin
        float2 halfSize = u.size * 0.5;
        float2 p = (in.uv - float2(0.5)) * u.size;

        float d = sdRoundBox(p, halfSize, u.cornerRadius);
        float aa = fwidth(d);
        if (aa <= 0.0) { aa = 1.0; }

        // Outer shape mask (anti-aliased)
        float outerAlpha = 1.0 - smoothstep(0.0, aa, d);
        if (outerAlpha <= 0.001) {
            discard_fragment();
        }

        if (u.borderWidth > 0.0 && u.borderColor.a > 0.0) {
            // Inner distance for border
            float innerD = d + u.borderWidth;
            float borderFactor = smoothstep(-aa, 0.0, innerD);
            float4 color = mix(u.fillColor, u.borderColor, borderFactor);
            return float4(color.rgb, color.a * outerAlpha);
        }

        return float4(u.fillColor.rgb, u.fillColor.a * outerAlpha);
    }

    // MARK: - Glassmorphism & Frosted Blur Shader

    struct GlassUniforms {
        float blurRadius;
        float saturation;
        float2 _padding;
        float4 tintColor;
    };


    fragment float4 glass_fragment(
        VertexOut in [[stage_in]],
        constant GlassUniforms &u [[buffer(0)]]
    ) {
        // Base glass gradient reflection simulation
        float2 uv = in.uv;
        float specular = pow(max(0.0, 1.0 - uv.y), 3.0) * 0.25;

        // Base frosted color
        float3 base = u.tintColor.rgb;

        // Saturation adjust
        float luma = dot(base, float3(0.2126, 0.7152, 0.0722));
        float3 saturated = mix(float3(luma), base, u.saturation);

        float3 finalRgb = saturated + float3(specular);
        float alpha = clamp(u.tintColor.a + specular * 0.5, 0.0, 1.0);

        return float4(finalRgb, alpha);
    }

    // MARK: - Mesh Gradient Shader

    struct MeshPoint {
        float2 pos;
        float4 color;
    };

    struct MeshGradientUniforms {
        int width;
        int height;
        int pointCount;
    };

    fragment float4 mesh_gradient_fragment(
        VertexOut in [[stage_in]],
        constant MeshGradientUniforms &u [[buffer(0)]],
        constant MeshPoint *points [[buffer(1)]]
    ) {
        float2 uv = in.uv;
        int w = u.width;
        int h = u.height;

        if (w < 2 || h < 2 || u.pointCount < w * h) {
            return float4(0.0);
        }

        // Determine which grid cell uv belongs to
        float fx = uv.x * float(w - 1);
        float fy = uv.y * float(h - 1);

        int col = clamp(int(floor(fx)), 0, w - 2);
        int row = clamp(int(floor(fy)), 0, h - 2);

        float tx = clamp(fx - float(col), 0.0, 1.0);
        float ty = clamp(fy - float(row), 0.0, 1.0);

        // Smooth cubic Hermite interpolation for smooth transitions
        tx = tx * tx * (3.0 - 2.0 * tx);
        ty = ty * ty * (3.0 - 2.0 * ty);

        // Fetch 4 corners of the cell
        int i00 = row * w + col;
        int i10 = row * w + (col + 1);
        int i01 = (row + 1) * w + col;
        int i11 = (row + 1) * w + (col + 1);

        float4 c00 = points[i00].color;
        float4 c10 = points[i10].color;
        float4 c01 = points[i01].color;
        float4 c11 = points[i11].color;

        // Bilinear interpolation
        float4 top = mix(c00, c10, tx);
        float4 bottom = mix(c01, c11, tx);
        float4 result = mix(top, bottom, ty);

        return result;
    }
    """
}
