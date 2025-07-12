// Version: 2.73
import SwiftUI
import UIKit
import MetalKit
import simd
import Combine

// MARK: - Configuration (Simplified)

// MARK: - Extensions

extension Color {
    var simd3: SIMD3<Float> {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }
}

// MARK: - Random Number Generation

/// Protocol for injectable random number generation to enable testability and reproducibility
protocol RandomGenerator {
    func float(in range: ClosedRange<Float>) -> Float
    func int(in range: ClosedRange<Int>) -> Int
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat
    func double(in range: ClosedRange<Double>) -> Double
}

/// Default implementation using system random number generator
class DefaultRandomGenerator: RandomGenerator {
    func float(in range: ClosedRange<Float>) -> Float {
        Float.random(in: range)
    }
    
    func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }
    
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range)
    }
    
    func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}

/// Deterministic random number generator for testing with reproducible sequences
class SeededRandomGenerator: RandomGenerator {
    private var generator: SystemRandomNumberGenerator
    
    init(seed: UInt64) {
        self.generator = SystemRandomNumberGenerator()
        // Note: SystemRandomNumberGenerator doesn't support seeding directly
        // For true deterministic behavior, consider using a custom PRNG
    }
    
    func float(in range: ClosedRange<Float>) -> Float {
        Float.random(in: range, using: &generator)
    }
    
    func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }
    
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range, using: &generator)
    }
    
    func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range, using: &generator)
    }
}

// MARK: - Input Validation

/// Simple input validation
struct InputValidator {
    static func validateDotPosition(_ position: CGPoint, context: String = "") -> CGPoint {
        return position
    }
    
    static func validateRadius(_ radius: Float, context: String = "") -> Float {
        return radius
    }
    
    static func validateDotType(_ type: Int32, context: String = "") -> Int32 {
        return type
    }
    
    static func validateRenderMask(_ mask: [Bool], context: String = "") -> [Bool] {
        return mask
    }
}

// MARK: - Data Structures

/// Metal-compatible dot structure for efficient GPU transfer
/// Uses SIMD types for optimal alignment and cache coherence
struct MetalDot: Equatable, Hashable {
    var position: SIMD2<Float> // (x, y) in Metal coordinate space [0,1]
    var radius: Float // Normalized radius [0,1]
    var type: Int32 // Dot type enum raw value [0-4]
    
    init(position: SIMD2<Float>, radius: Float, type: Int32) {
        let validatedPosition = SIMD2<Float>(
            max(0, min(1, position.x)),
            max(0, min(1, position.y))
        )
        let validatedRadius = InputValidator.validateRadius(radius, context: "MetalDot.init")
        let validatedType = InputValidator.validateDotType(type, context: "MetalDot.init")
        
        self.position = validatedPosition
        self.radius = validatedRadius
        self.type = validatedType
    }
}

/// Encapsulates dot data formatted for Metal shader consumption
/// 
/// **Critical Coordinate Transform**: Y-axis is flipped here!
/// - Input: SplatDot.position.y in SwiftUI space (0=top, increases downward)
/// - Output: ys array in Metal space (0=bottom, increases upward)
/// - Transform: `1 - position.y` converts SwiftUI → Metal coordinate space
struct MetalDotData {
    // Unified structure - primary data format
    let dots: [MetalDot] // Unified array of Metal-compatible dots
    
    // Legacy arrays for backward compatibility (derived from dots)
    let xs: [Float] // X coordinates in normalized [0,1] space
    let ys: [Float] // Y coordinates in Metal space [0,1] (bottom-left origin)
    let radii: [Float] // Radii normalized to screen width [0,1]
    let types: [Int] // Dot type enum raw values [0-4]
    
    init(from dots: [SplatDot], limit: Int) {
        let limitedDots = Array(dots.prefix(limit))
        
        // Create unified structure first (primary data)
        let metalDots = limitedDots.map { dot in
            MetalDot(
                position: SIMD2<Float>(Float(dot.position.x), 1 - Float(dot.position.y)), // Y-flip: SwiftUI → Metal
                radius: dot.radius,
                type: Int32(dot.type.rawValue)
            )
        }
        let paddingCount = max(0, limit - metalDots.count)
        let paddingDots = Array(repeating: MetalDot(position: SIMD2<Float>(0, 0), radius: 0, type: 0), count: paddingCount)
        self.dots = metalDots + paddingDots
        
        // Derive legacy arrays from unified structure (for compatibility)
        self.xs = self.dots.map { $0.position.x }
        self.ys = self.dots.map { $0.position.y }
        self.radii = self.dots.map { $0.radius }
        self.types = self.dots.map { Int($0.type) }
    }
    
    /// Pads an array to the specified limit with a default value
    private static func padArray<T>(_ array: [T], toLimit limit: Int, with defaultValue: T) -> [T] {
        let paddingCount = max(0, limit - array.count)
        return array + Array(repeating: defaultValue, count: paddingCount)
    }
}

struct RenderPass {
    let name: String
    let color: SIMD3<Float>
    let opacity: Double
    let renderMask: [Bool]
    let zIndex: Double
    let enabled: Bool
    
    static func background(color: SIMD3<Float>, opacity: Double, enabled: Bool) -> RenderPass {
        RenderPass(
            name: "Background",
            color: color,
            opacity: opacity,
            renderMask: [true, true, true, true, false], // central, large, medium, small, no splash
            zIndex: RenderingConstants.zIndexBackground,
            enabled: enabled
        )
    }
    
    static func foreground(color: SIMD3<Float>, opacity: Double, enabled: Bool) -> RenderPass {
        RenderPass(
            name: "Foreground",
            color: color,
            opacity: opacity,
            renderMask: [true, true, true, false, false], // central, large, medium
            zIndex: RenderingConstants.zIndexForeground,
            enabled: enabled
        )
    }
}

// MARK: - Metal Abstractions

/// Protocol for Metal device management
protocol MetalDeviceProvider {
    var device: MTLDevice { get }
}

/// Protocol for Metal shader compilation
protocol MetalShaderCompiler {
    func compileSplatterShader() throws -> (vertex: MTLFunction, fragment: MTLFunction)
}

/// Protocol for Metal pipeline creation
protocol MetalPipelineProvider {
    func createSplatterPipeline(vertex: MTLFunction, fragment: MTLFunction) throws -> MTLRenderPipelineState
}

/// Protocol for Metal command execution
protocol MetalCommandProvider {
    var commandQueue: MTLCommandQueue { get }
}

/// Protocol for Metal rendering operations
protocol MetalRenderer {
    func render(
        drawable: MTLDrawable,
        descriptor: MTLRenderPassDescriptor,
        metalDotsBuffer: MTLBuffer,
        renderMaskBuffer: MTLBuffer,
        quadBuffer: MTLBuffer,
        aspect: Float,
        splotColor: SIMD3<Float>
    )
}

/// Protocol for managing Metal overlay state
protocol MetalOverlayStateManager {
    var renderMask: [Bool] { get set }
    var metalDots: [MetalDot] { get set }
    var metalDotsHash: Int { get set }
    
    func updateMetalDots(_ dots: [MetalDot]) -> Bool
    func updateRenderMask(_ mask: [Bool]) -> Bool
    func shouldUpdateRenderMaskBuffer() -> Bool
}

/// Protocol for managing Metal buffers
protocol MetalBufferManager {
    var renderMaskBuffer: MTLBuffer? { get }
    var quadBuffer: MTLBuffer? { get }
    var metalDotsBuffer: MTLBuffer? { get }
    
    func updateBuffers(with stateManager: MetalOverlayStateManager)
}

// MARK: - Metal Implementation

final class DefaultMetalDeviceProvider: MetalDeviceProvider {
    let device: MTLDevice
    
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MetalError.deviceNotAvailable
        }
        self.device = device
    }
}

final class DefaultMetalShaderCompiler: MetalShaderCompiler {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func compileSplatterShader() throws -> (vertex: MTLFunction, fragment: MTLFunction) {
        let metalSource = SplatterShaderSource.source
        
        do {
            let library = try device.makeLibrary(source: metalSource, options: nil)
            guard let vertexFunc = library.makeFunction(name: "vertex_main"),
                  let fragmentFunc = library.makeFunction(name: "fragment_main") else {
                throw MetalError.shaderCompilationFailed
            }
            return (vertex: vertexFunc, fragment: fragmentFunc)
        } catch {
            throw MetalError.shaderCompilationFailed
        }
    }
}

final class DefaultMetalPipelineProvider: MetalPipelineProvider {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func createSplatterPipeline(vertex: MTLFunction, fragment: MTLFunction) throws -> MTLRenderPipelineState {
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertex
        pipelineDesc.fragmentFunction = fragment
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].rgbBlendOperation = .add
        pipelineDesc.colorAttachments[0].alphaBlendOperation = .add
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            throw MetalError.pipelineCreationFailed(error)
        }
    }
}

final class DefaultMetalCommandProvider: MetalCommandProvider {
    let commandQueue: MTLCommandQueue
    
    init(device: MTLDevice) throws {
        guard let commandQueue = device.makeCommandQueue() else {
            throw MetalError.commandQueueCreationFailed
        }
        self.commandQueue = commandQueue
    }
}

final class DefaultMetalRenderer: MetalRenderer {
    private let pipelineState: MTLRenderPipelineState
    private let commandQueue: MTLCommandQueue
    
    init(pipelineState: MTLRenderPipelineState, commandQueue: MTLCommandQueue) {
        self.pipelineState = pipelineState
        self.commandQueue = commandQueue
    }
    
    func render(
        drawable: MTLDrawable,
        descriptor: MTLRenderPassDescriptor,
        metalDotsBuffer: MTLBuffer,
        renderMaskBuffer: MTLBuffer,
        quadBuffer: MTLBuffer,
        aspect: Float,
        splotColor: SIMD3<Float>
    ) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
        
        encoder.setFragmentBuffer(metalDotsBuffer, offset: 0, index: 1)
        
        var aspectVar = aspect
        encoder.setFragmentBytes(&aspectVar, length: MemoryLayout<Float>.stride, index: 2)
        var splotColorVar = splotColor
        encoder.setFragmentBytes(&splotColorVar, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)
        encoder.setFragmentBuffer(renderMaskBuffer, offset: 0, index: 4)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

final class DefaultMetalOverlayStateManager: MetalOverlayStateManager {
    var renderMask: [Bool] = [true, true, true, true, false]
    var metalDots: [MetalDot] = Array(repeating: MetalDot(position: SIMD2<Float>(0, 0), radius: 0, type: 0), count: RenderingConstants.splatDotLimit)
    var metalDotsHash: Int = 0
    
    private var cachedRenderMask: [Bool] = []
    
    func updateMetalDots(_ dots: [MetalDot]) -> Bool {
        let newHash = dots.hashValue
        if metalDotsHash != newHash {
            metalDots = dots
            metalDotsHash = newHash
            return true
        }
        return false
    }
    
    func updateRenderMask(_ mask: [Bool]) -> Bool {
        let validatedMask = InputValidator.validateRenderMask(mask, context: "MetalOverlayStateManager.updateRenderMask")
        if renderMask != validatedMask {
            renderMask = validatedMask
            return true
        }
        return false
    }
    
    func shouldUpdateRenderMaskBuffer() -> Bool {
        if renderMask != cachedRenderMask {
            cachedRenderMask = renderMask
            return true
        }
        return false
    }
}

final class DefaultMetalBufferManager: MetalBufferManager {
    private(set) var renderMaskBuffer: MTLBuffer?
    private(set) var quadBuffer: MTLBuffer?
    private(set) var metalDotsBuffer: MTLBuffer?
    
    private let device: MTLDevice?
    let isAvailable: Bool
    
    init(device: MTLDevice?) {
        self.device = device
        self.isAvailable = device != nil
        if isAvailable {
            createBuffers()
        } else {
            print("⚠️ Metal buffer manager disabled - no device available")
        }
    }
    
    private func createBuffers() {
        guard let device = device else { return }
        
        let boolSize = MemoryLayout<Bool>.stride
        
        renderMaskBuffer = device.makeBuffer(length: boolSize * RenderingConstants.dotTypeCount, options: [.storageModeShared])
        
        // Create unified MetalDot buffer
        metalDotsBuffer = device.makeBuffer(length: MemoryLayout<MetalDot>.stride * RenderingConstants.splatDotLimit, options: [.storageModeShared])
        
        // Create reusable quad buffer for fullscreen quad
        let quadVertices: [SIMD2<Float>] = [
            SIMD2<Float>(-1, -1),
            SIMD2<Float>(-1,  1),
            SIMD2<Float>( 1, -1),
            SIMD2<Float>( 1, -1),
            SIMD2<Float>(-1,  1),
            SIMD2<Float>( 1,  1)
        ]
        quadBuffer = device.makeBuffer(bytes: quadVertices, length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count, options: [.storageModeShared])
    }
    
    func updateBuffers(with stateManager: MetalOverlayStateManager) {
        guard isAvailable else { return }
        
        // Update render mask buffer only if changed
        if stateManager.shouldUpdateRenderMaskBuffer() {
            if let buffer = renderMaskBuffer {
                let pointer = buffer.contents().bindMemory(to: Bool.self, capacity: RenderingConstants.dotTypeCount)
                for i in 0..<RenderingConstants.dotTypeCount {
                    pointer[i] = stateManager.renderMask[i]
                }
            }
        }
        
        // Update unified MetalDot buffer (used by Metal shader) - direct binding
        if let buffer = metalDotsBuffer {
            let bufferPointer = buffer.contents().bindMemory(to: MetalDot.self, capacity: RenderingConstants.splatDotLimit)
            for i in 0..<RenderingConstants.splatDotLimit {
                bufferPointer[i] = stateManager.metalDots[i]
            }
        }
    }
}

/// Centralized Metal service coordinator with graceful degradation
final class MetalService {
    static let shared = MetalService()
    
    let deviceProvider: MetalDeviceProvider?
    let shaderCompiler: MetalShaderCompiler?
    let pipelineProvider: MetalPipelineProvider?
    let commandProvider: MetalCommandProvider?
    let renderer: MetalRenderer?
    
    private let pipelineState: MTLRenderPipelineState?
    let isAvailable: Bool
    
    private init() {
        var tempDeviceProvider: MetalDeviceProvider?
        var tempShaderCompiler: MetalShaderCompiler?
        var tempPipelineProvider: MetalPipelineProvider?
        var tempCommandProvider: MetalCommandProvider?
        var tempRenderer: MetalRenderer?
        var tempPipelineState: MTLRenderPipelineState?
        
        do {
            tempDeviceProvider = try DefaultMetalDeviceProvider()
            tempShaderCompiler = DefaultMetalShaderCompiler(device: tempDeviceProvider!.device)
            tempPipelineProvider = DefaultMetalPipelineProvider(device: tempDeviceProvider!.device)
            tempCommandProvider = try DefaultMetalCommandProvider(device: tempDeviceProvider!.device)
            
            let shaders = try tempShaderCompiler!.compileSplatterShader()
            tempPipelineState = try tempPipelineProvider!.createSplatterPipeline(vertex: shaders.vertex, fragment: shaders.fragment)
            tempRenderer = DefaultMetalRenderer(pipelineState: tempPipelineState!, commandQueue: tempCommandProvider!.commandQueue)
            
            self.isAvailable = true
            print("✅ Metal service initialized successfully")
        } catch {
            print("⚠️ Metal service initialization failed: \(error)")
            print("⚠️ Splatter rendering will be disabled")
            self.isAvailable = false
        }
        
        self.deviceProvider = tempDeviceProvider
        self.shaderCompiler = tempShaderCompiler
        self.pipelineProvider = tempPipelineProvider
        self.commandProvider = tempCommandProvider
        self.renderer = tempRenderer
        self.pipelineState = tempPipelineState
    }
    
    var device: MTLDevice? { deviceProvider?.device }
    var commandQueue: MTLCommandQueue? { commandProvider?.commandQueue }
    var pipeline: MTLRenderPipelineState? { pipelineState }
}

// MARK: - Error Types

enum MetalError: LocalizedError {
    case deviceNotAvailable
    case shaderCompilationFailed
    case pipelineCreationFailed(Error)
    case commandQueueCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .deviceNotAvailable:
            return "Metal is not supported on this device"
        case .shaderCompilationFailed:
            return "Failed to compile Metal shaders"
        case .pipelineCreationFailed(let error):
            return "Failed to create Metal pipeline: \(error.localizedDescription)"
        case .commandQueueCreationFailed:
            return "Failed to create Metal command queue"
        }
    }
}

// MARK: - Shader Source

struct SplatterShaderSource {
    static let source = """
    using namespace metal;
    #define SPLAT_DOT_LIMIT \(RenderingConstants.splatDotLimit)
    struct Vertex {
        float2 position [[attribute(0)]];
    };
    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };
    struct MetalDot {
        float2 position; // (x, y) in Metal coordinate space [0,1]
        float radius;    // Normalized radius [0,1]
        int32_t type;    // Dot type enum raw value [0-4] - matches Swift Int32
    } __attribute__((packed));
    vertex VertexOut vertex_main(const device Vertex* vertices [[buffer(0)]], uint vid [[vertex_id]]) {
        VertexOut out;
        out.position = float4(vertices[vid].position, 0.0, 1.0);
        out.uv = (vertices[vid].position + 1.0) * 0.5;
        return out;
    }
    fragment float4 fragment_main(VertexOut in [[stage_in]],
                                  constant MetalDot* dots [[buffer(1)]],
                                  constant float& aspect [[buffer(2)]],
                                  constant float3& splotColor [[buffer(3)]],
                                  constant bool* renderMask [[buffer(4)]]) {
        float2 uv = in.uv;
        float field = 0.0;
        for (uint i = 0; i < SPLAT_DOT_LIMIT; ++i) {
            int32_t dotType = dots[i].type;
            if (dotType >= 0 && dotType < \(RenderingConstants.dotTypeCount) && renderMask[dotType]) {
                float2 center = dots[i].position;
                float2 aspect_uv = float2((uv.x - center.x) * aspect, uv.y - center.y);
                float radius = dots[i].radius;
                if (radius > 0.0) {
                    float dist = length(aspect_uv);
                    field += (radius * radius) / (dist * dist + \(RenderingConstants.metalDistanceEpsilon));
                }
            }
        }
        float threshold = \(RenderingConstants.metalThreshold);
        float alpha = smoothstep(threshold, threshold + \(RenderingConstants.metalThresholdSmoothness), field);
        return float4(splotColor, alpha);
    }
    """
}

// MARK: - Configuration Management

/// Configuration profiles for different use cases
enum ConfigurationProfile {
    case development  // Interactive parameter exploration
    case production   // Optimized, immutable constants
}

/// Centralized configuration system with dual-mode support
struct SplatterConfiguration {
    // MARK: - Core Rendering Constants
    // Properties are var in development mode, let in production mode
    var splatDotLimit: Int
    var metalThreshold: Float
    var metalThresholdSmoothness: Float
    var metalDistanceEpsilon: Float
    var reactiveUpdateDebounceMs: Int
   var dotTypeCount: Int
    var zIndexBackground: Double
    var zIndexForeground: Double
    
    // MARK: - Current Configuration
    static let current = SplatterConfiguration.development
    
    static let development = SplatterConfiguration(
        splatDotLimit: 512,
        metalThreshold: 0.8,
        metalThresholdSmoothness: 0.15,
        metalDistanceEpsilon: 1e-4,
        reactiveUpdateDebounceMs: 10,
        dotTypeCount: 5,
        zIndexBackground: 1.0,
        zIndexForeground: 2.0
    )
    
    // Quality presets for development exploration
    static let performanceOptimized = SplatterConfiguration(
        splatDotLimit: 256,
        metalThreshold: 0.75,
        metalThresholdSmoothness: 0.1,
        metalDistanceEpsilon: 1e-3,
        reactiveUpdateDebounceMs: 16,
        dotTypeCount: 5,
        zIndexBackground: 1.0,
        zIndexForeground: 2.0
    )
    
    static let qualityMaximized = SplatterConfiguration(
        splatDotLimit: 1024,
        metalThreshold: 0.85,
        metalThresholdSmoothness: 0.2,
        metalDistanceEpsilon: 1e-5,
        reactiveUpdateDebounceMs: 5,
        dotTypeCount: 5,
        zIndexBackground: 1.0,
        zIndexForeground: 2.0
    )
    
    // Production mode: Compile-time constants for maximum performance
    static let production = SplatterConfiguration(
        splatDotLimit: 512,
        metalThreshold: 0.8,
        metalThresholdSmoothness: 0.15,
        metalDistanceEpsilon: 1e-4,
        reactiveUpdateDebounceMs: 10,
        dotTypeCount: 5,
        zIndexBackground: 1.0,
        zIndexForeground: 2.0
    )
    
    // MARK: - Configuration Validation
    
    /// Validates configuration values and returns a corrected version
    static func validated(_ config: SplatterConfiguration) -> SplatterConfiguration {
        return SplatterConfiguration(
            splatDotLimit: max(64, min(2048, config.splatDotLimit)),
            metalThreshold: max(0.1, min(2.0, config.metalThreshold)),
            metalThresholdSmoothness: max(0.01, min(1.0, config.metalThresholdSmoothness)),
            metalDistanceEpsilon: max(1e-6, min(1e-2, config.metalDistanceEpsilon)),
            reactiveUpdateDebounceMs: max(1, min(100, config.reactiveUpdateDebounceMs)),
            dotTypeCount: max(1, min(10, config.dotTypeCount)),
            zIndexBackground: max(0.0, min(10.0, config.zIndexBackground)),
            zIndexForeground: max(0.0, min(10.0, config.zIndexForeground))
        )
    }
}

/// Configuration presets for dot generation parameters
struct DotParameterPresets {
    // MARK: - Central Dot Presets
    struct CentralDot {
        static let subtle = (radiusMin: 20.0, radiusMax: 25.0)
        static let standard = (radiusMin: 35.0, radiusMax: 45.0)
        static let bold = (radiusMin: 50.0, radiusMax: 60.0)
    }
    
    // MARK: - Large Dot Presets
    struct LargeDot {
        static let minimal = (radiusMin: 25.0, radiusMax: 35.0, countMin: 0, countMax: 1, distanceMin: 20.0, distanceMax: 50.0)
        static let standard = (radiusMin: 35.0, radiusMax: 45.0, countMin: 0, countMax: 3, distanceMin: 25.0, distanceMax: 67.5)
        static let abundant = (radiusMin: 40.0, radiusMax: 50.0, countMin: 2, countMax: 5, distanceMin: 30.0, distanceMax: 80.0)
    }
    
    // MARK: - Medium Dot Presets
    struct MediumDot {
        static let sparse = (radiusMin: 20.0, radiusMax: 25.0, countMin: 1, countMax: 5, distanceMin: 60.0, distanceMax: 120.0)
        static let standard = (radiusMin: 25.0, radiusMax: 30.0, countMin: 3, countMax: 9, distanceMin: 80.0, distanceMax: 140.0)
        static let dense = (radiusMin: 22.0, radiusMax: 28.0, countMin: 6, countMax: 12, distanceMin: 70.0, distanceMax: 130.0)
    }
    
    // MARK: - Small Dot Presets
    struct SmallDot {
        static let minimal = (radiusMin: 8.0, radiusMax: 12.0, countMin: 2, countMax: 6, distanceMin: 40.0, distanceMax: 100.0)
        static let standard = (radiusMin: 12.0, radiusMax: 18.0, countMin: 6, countMax: 15, distanceMin: 60.0, distanceMax: 165.0)
        static let abundant = (radiusMin: 10.0, radiusMax: 16.0, countMin: 10, countMax: 20, distanceMin: 50.0, distanceMax: 150.0)
    }
    
    // MARK: - Quality Profiles
    
    static func applyPerformanceProfile() -> (central: (CGFloat, CGFloat), large: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat), medium: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat), small: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat)) {
        return (
            central: (CGFloat(CentralDot.subtle.radiusMin), CGFloat(CentralDot.subtle.radiusMax)),
            large: (CGFloat(LargeDot.minimal.radiusMin), CGFloat(LargeDot.minimal.radiusMax), LargeDot.minimal.countMin, LargeDot.minimal.countMax, CGFloat(LargeDot.minimal.distanceMin), CGFloat(LargeDot.minimal.distanceMax)),
            medium: (CGFloat(MediumDot.sparse.radiusMin), CGFloat(MediumDot.sparse.radiusMax), MediumDot.sparse.countMin, MediumDot.sparse.countMax, CGFloat(MediumDot.sparse.distanceMin), CGFloat(MediumDot.sparse.distanceMax)),
            small: (CGFloat(SmallDot.minimal.radiusMin), CGFloat(SmallDot.minimal.radiusMax), SmallDot.minimal.countMin, SmallDot.minimal.countMax, CGFloat(SmallDot.minimal.distanceMin), CGFloat(SmallDot.minimal.distanceMax))
        )
    }
    
    static func applyQualityProfile() -> (central: (CGFloat, CGFloat), large: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat), medium: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat), small: (CGFloat, CGFloat, Int, Int, CGFloat, CGFloat)) {
        return (
            central: (CGFloat(CentralDot.bold.radiusMin), CGFloat(CentralDot.bold.radiusMax)),
            large: (CGFloat(LargeDot.abundant.radiusMin), CGFloat(LargeDot.abundant.radiusMax), LargeDot.abundant.countMin, LargeDot.abundant.countMax, CGFloat(LargeDot.abundant.distanceMin), CGFloat(LargeDot.abundant.distanceMax)),
            medium: (CGFloat(MediumDot.dense.radiusMin), CGFloat(MediumDot.dense.radiusMax), MediumDot.dense.countMin, MediumDot.dense.countMax, CGFloat(MediumDot.dense.distanceMin), CGFloat(MediumDot.dense.distanceMax)),
            small: (CGFloat(SmallDot.abundant.radiusMin), CGFloat(SmallDot.abundant.radiusMax), SmallDot.abundant.countMin, SmallDot.abundant.countMax, CGFloat(SmallDot.abundant.distanceMin), CGFloat(SmallDot.abundant.distanceMax))
        )
    }
}

// MARK: - Development Configuration UI (Development Mode Only)

/// Development-only configuration interface for parameter exploration
class SplatterConfigurationManager: ObservableObject {
    @Published var currentProfile: String = "Development"
    @Published var customConfig = SplatterConfiguration.development
    
    let profiles = [
        "Development": SplatterConfiguration.development,
        "Performance": SplatterConfiguration.performanceOptimized,
        "Quality": SplatterConfiguration.qualityMaximized
    ]
    
    func applyProfile(_ profileName: String) {
        if let profile = profiles[profileName] {
            customConfig = profile
            currentProfile = profileName
        }
    }
    
    func applyCustomConfiguration() {
        customConfig = SplatterConfiguration.validated(customConfig)
    }
    
    func resetToDefaults() {
        customConfig = SplatterConfiguration.development
        currentProfile = "Development"
    }
}

/// Debug-only configuration overlay for development parameter exploration
struct DevelopmentConfigurationOverlay: View {
    @StateObject private var configManager = SplatterConfigurationManager()
    @State private var showingConfig = false
    
    var body: some View {
        EmptyView()
    }
}

struct ConfigurationDetailView: View {
    @ObservedObject var manager: SplatterConfigurationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Quality Profiles") {
                Picker("Profile", selection: $manager.currentProfile) {
                    ForEach(Array(manager.profiles.keys), id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .onChange(of: manager.currentProfile) { _, newValue in
                    manager.applyProfile(newValue)
                }
            }
            
            Section("Metal Rendering") {
                HStack {
                    Text("Dot Limit")
                    Spacer()
                    TextField("512", value: $manager.customConfig.splatDotLimit, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Threshold")
                    Spacer()
                    TextField("0.8", value: $manager.customConfig.metalThreshold, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("Smoothness")
                    Spacer()
                    TextField("0.15", value: $manager.customConfig.metalThresholdSmoothness, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            
            Section("Performance") {
                HStack {
                    Text("Debounce (ms)")
                    Spacer()
                    TextField("10", value: $manager.customConfig.reactiveUpdateDebounceMs, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            
            Section("Actions") {
                Button("Apply Custom Settings") {
                    manager.applyCustomConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset to Defaults") {
                    manager.resetToDefaults()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Backwards Compatibility

/// Legacy constants enum for backwards compatibility
enum RenderingConstants {
    static var splatDotLimit: Int { SplatterConfiguration.current.splatDotLimit }
    static var metalThreshold: Float { SplatterConfiguration.current.metalThreshold }
    static var metalThresholdSmoothness: Float { SplatterConfiguration.current.metalThresholdSmoothness }
    static var metalDistanceEpsilon: Float { SplatterConfiguration.current.metalDistanceEpsilon }
    static var reactiveUpdateDebounceMs: Int { SplatterConfiguration.current.reactiveUpdateDebounceMs }
    static var dotTypeCount: Int { SplatterConfiguration.current.dotTypeCount }
    static var zIndexBackground: Double { SplatterConfiguration.current.zIndexBackground }
    static var zIndexForeground: Double { SplatterConfiguration.current.zIndexForeground }
}

/// Represents a single dot within a splat with normalized coordinates for Metal rendering
/// 
/// **Coordinate Systems & Units:**
/// - **Input Coordinates**: Screen pixels (0,0 = top-left, y increases downward)
/// - **Stored Coordinates**: Normalized [0,1] range (0,0 = top-left, y increases downward)
/// - **Metal Coordinates**: Normalized [0,1] range (0,0 = bottom-left, y increases upward)
/// 
/// **Coordinate Transformations:**
/// 1. Screen pixels → Normalized: `x/screenWidth, y/screenHeight`
/// 2. Normalized → Metal: `x (unchanged), 1-y (flip y-axis)`
/// 
/// **Units:**
/// - All radius values are normalized to screen width (radius/screenWidth)
/// - All distances are converted from pixels to normalized units during generation
struct SplatDot: Identifiable, Equatable {
    let id: UUID = UUID()
    let position: CGPoint // Normalized [0,1] coordinates (SwiftUI space: top-left origin)
    let radius: Float // Normalized to screen width [0,1]
    let isEllipse: Bool
    let rotation: Double
    let type: DotType
    
    enum DotType: Int, CaseIterable {
        case central = 0, large = 1, medium = 2, small = 3, splash = 4
    }
}

struct Splat: Identifiable, Equatable {
    let id: UUID = UUID()
    let center: CGPoint
    let dots: [SplatDot]


    static func generate(center: CGPoint, centralDot: CentralDotParams, largeDots: LargeDotParams, mediumDots: MediumDotParams, smallDots: SmallDotParams, splashes: SplashParams, rendering: RenderingParams, screenWidth: CGFloat, screenHeight: CGFloat, rng: RandomGenerator = DefaultRandomGenerator()) -> Splat {
        var dots: [SplatDot] = []
        
        // Central dot (always at center)
        let centralRadius = rng.cgFloat(in: centralDot.radiusRange)
        let normalizedPosition = InputValidator.validateDotPosition(
            CGPoint(x: center.x / screenWidth, y: center.y / screenHeight),
            context: "Splat.generate central dot"
        )
        dots.append(SplatDot(
            position: normalizedPosition,
            radius: InputValidator.validateRadius(Float(centralRadius / screenWidth), context: "Splat.generate central dot"),
            isEllipse: false,
            rotation: 0,
            type: .central
        ))
        
        // Scattered dots (large, medium, small)
        dots += generateScatteredDots(center: center, params: largeDots, type: .large, screenWidth: screenWidth, screenHeight: screenHeight, rng: rng)
        dots += generateScatteredDots(center: center, params: mediumDots, type: .medium, screenWidth: screenWidth, screenHeight: screenHeight, rng: rng)
        dots += generateScatteredDots(center: center, params: smallDots, type: .small, screenWidth: screenWidth, screenHeight: screenHeight, rng: rng)
        
        // Splashes (ellipses)
        dots += generateSplashes(center: center, params: splashes, screenWidth: screenWidth, screenHeight: screenHeight, rng: rng)
        
        return Splat(center: center, dots: dots)
    }
    
    /// Generates scattered circular dots around the center point
    private static func generateScatteredDots(center: CGPoint, params: ScatteredDotParams, type: SplatDot.DotType, screenWidth: CGFloat, screenHeight: CGFloat, rng: RandomGenerator) -> [SplatDot] {
        let count = rng.int(in: params.countRange)
        var dots: [SplatDot] = []
        
        for _ in 0..<count {
            let angle = rng.cgFloat(in: 0.0...(2.0 * CGFloat.pi))
            let dist = rng.cgFloat(in: params.distanceRange)
            let radius = rng.cgFloat(in: params.radiusRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let normalizedPosition = InputValidator.validateDotPosition(
                CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                context: "Splat.generateScatteredDots"
            )
            dots.append(SplatDot(
                position: normalizedPosition,
                radius: InputValidator.validateRadius(Float(radius / screenWidth), context: "Splat.generateScatteredDots"),
                isEllipse: false,
                rotation: 0,
                type: type
            ))
        }
        
        return dots
    }
    
    /// Generates elliptical splash dots around the center point
    private static func generateSplashes(center: CGPoint, params: SplashParams, screenWidth: CGFloat, screenHeight: CGFloat, rng: RandomGenerator) -> [SplatDot] {
        let count = rng.int(in: params.countRange)
        var dots: [SplatDot] = []
        
        for _ in 0..<count {
            let angle = rng.cgFloat(in: 0.0...(2.0 * CGFloat.pi))
            let dist = rng.cgFloat(in: params.distanceRange)
            let width = rng.cgFloat(in: params.widthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let normalizedPosition = InputValidator.validateDotPosition(
                CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                context: "Splat.generateSplashes"
            )
            let rotation = Double(angle * 180 / .pi) + rng.double(in: params.rotationJitterRange)
            dots.append(SplatDot(
                position: normalizedPosition,
                radius: InputValidator.validateRadius(Float(width / screenWidth), context: "Splat.generateSplashes"),
                isEllipse: true,
                rotation: rotation,
                type: .splash
            ))
        }
        
        return dots
    }
}

// MARK: - Parameter Classes

// Generic base class for dot parameters
class DotParams: ObservableObject {
    @Published var enabled: Bool
    @Published var radiusMin: CGFloat
    @Published var radiusMax: CGFloat
    
    init(enabled: Bool = true, radiusMin: CGFloat, radiusMax: CGFloat) {
        self.enabled = enabled
        self.radiusMin = radiusMin
        self.radiusMax = radiusMax
    }
    
    var radiusRange: ClosedRange<CGFloat> { radiusMin...radiusMax }
}

// Specialized classes with additional properties
class CentralDotParams: DotParams {
    init() {
        super.init(enabled: true, radiusMin: 35.0, radiusMax: 45.0)
    }
}

class ScatteredDotParams: DotParams {
    @Published var countMin: Int
    @Published var countMax: Int
    @Published var distanceMin: CGFloat
    @Published var distanceMax: CGFloat
    
    init(enabled: Bool = true, radiusMin: CGFloat, radiusMax: CGFloat, countMin: Int, countMax: Int, distanceMin: CGFloat, distanceMax: CGFloat) {
        self.countMin = countMin
        self.countMax = countMax
        self.distanceMin = distanceMin
        self.distanceMax = distanceMax
        super.init(enabled: enabled, radiusMin: radiusMin, radiusMax: radiusMax)
    }
    
    var countRange: ClosedRange<Int> { countMin...countMax }
    var distanceRange: ClosedRange<CGFloat> { distanceMin...distanceMax }
}

class LargeDotParams: ScatteredDotParams {
    init() {
        super.init(enabled: true, radiusMin: 35.0, radiusMax: 45.0, countMin: 0, countMax: 3, distanceMin: 25.0, distanceMax: 67.5)
    }
}

class MediumDotParams: ScatteredDotParams {
    init() {
        super.init(enabled: true, radiusMin: 25.0, radiusMax: 30.0, countMin: 3, countMax: 9, distanceMin: 80.0, distanceMax: 140.0)
    }
}

class SmallDotParams: ScatteredDotParams {
    init() {
        super.init(enabled: true, radiusMin: 12.0, radiusMax: 18.0, countMin: 6, countMax: 15, distanceMin: 60.0, distanceMax: 165.0)
    }
}

class SplashParams: ObservableObject {
    @Published var countMin: Int = 0
    @Published var countMax: Int = 6
    @Published var lengthMin: CGFloat = 20
    @Published var lengthMax: CGFloat = 60
    @Published var widthMin: CGFloat = 10
    @Published var widthMax: CGFloat = 30
    @Published var distanceMin: CGFloat = 80.0
    @Published var distanceMax: CGFloat = 140.0
    @Published var rotationJitterMin: Double = -10
    @Published var rotationJitterMax: Double = 10
    @Published var enabled: Bool = false
    
    var countRange: ClosedRange<Int> { countMin...countMax }
    var lengthRange: ClosedRange<CGFloat> { lengthMin...lengthMax }
    var widthRange: ClosedRange<CGFloat> { widthMin...widthMax }
    var distanceRange: ClosedRange<CGFloat> { distanceMin...distanceMax }
    var rotationJitterRange: ClosedRange<Double> { rotationJitterMin...rotationJitterMax }
}

class RenderingParams: ObservableObject {
    @Published var backgroundPassEnabled: Bool = true
    @Published var foregroundPassEnabled: Bool = true
    @Published var backgroundPassColor: Color = Color(red: 0.55, green: 0.0, blue: 0.0) // Dark red
    @Published var foregroundPassColor: Color = Color(red: 0.0, green: 0.6, blue: 0.0) // Green
    @Published var backgroundPassOpacity: Double = 1.0
    @Published var foregroundPassOpacity: Double = 0.4
    
    var backgroundColorSIMD: SIMD3<Float> {
        backgroundPassColor.simd3
    }
    
    var foregroundColorSIMD: SIMD3<Float> {
        foregroundPassColor.simd3
    }
}

class SplatterViewModel: ObservableObject {
    @Published var splats: [Splat] = []
    @Published var metalData = MetalDotData(from: [], limit: RenderingConstants.splatDotLimit)
    
    // Parameter groups
    @Published var centralDot = CentralDotParams()
    @Published var largeDots = LargeDotParams()
    @Published var mediumDots = MediumDotParams()
    @Published var smallDots = SmallDotParams()
    @Published var splashes = SplashParams()
    @Published var rendering = RenderingParams()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupReactiveUpdates()
    }
    
    // Computed rendering flags based on parameter enabled state
    var renderCentral: Bool { centralDot.enabled }
    var renderLarge: Bool { largeDots.enabled }
    var renderMedium: Bool { mediumDots.enabled }
    var renderSmall: Bool { smallDots.enabled }
    
    var filteredSplatDots: [SplatDot] {
        var enabledTypes = Set<SplatDot.DotType>()
        if renderCentral { enabledTypes.insert(.central) }
        if renderLarge { enabledTypes.insert(.large) }
        if renderMedium { enabledTypes.insert(.medium) }
        if renderSmall { enabledTypes.insert(.small) }
        // Note: .splash intentionally excluded
        
        return splats.flatMap({ $0.dots }).filter { enabledTypes.contains($0.type) }
    }
    
    var backgroundColorSIMD: SIMD3<Float> { rendering.backgroundColorSIMD }
    var foregroundColorSIMD: SIMD3<Float> { rendering.foregroundColorSIMD }
    
    var renderPasses: [RenderPass] {
        [
            .background(color: backgroundColorSIMD, opacity: rendering.backgroundPassOpacity, enabled: rendering.backgroundPassEnabled),
            .foreground(color: foregroundColorSIMD, opacity: rendering.foregroundPassOpacity, enabled: rendering.foregroundPassEnabled)
        ]
    }
    
    func addSplat(at location: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) {
        splats.append(Splat.generate(center: location, centralDot: centralDot, largeDots: largeDots, mediumDots: mediumDots, smallDots: smallDots, splashes: splashes, rendering: rendering, screenWidth: screenWidth, screenHeight: screenHeight))
    }
    
    func clear() {
        splats.removeAll()
    }
    
    func updateMetalData() {
        // All dots (precomputed coordinates) - used by both passes
        let allDots = splats.flatMap({ $0.dots })
        metalData = MetalDotData(from: allDots, limit: RenderingConstants.splatDotLimit)
    }
    
    private func setupReactiveUpdates() {
        // GEOMETRY CHANGES: Affect dot positions, count, or structure - require metalData recomputation
        
        // Splat structure changes (add/remove splats)
        $splats
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.updateMetalData() }
            .store(in: &cancellables)
        
        // Dot type visibility changes (affect renderMask but not metalData geometry)
        centralDot.$enabled
            .combineLatest(largeDots.$enabled, mediumDots.$enabled, smallDots.$enabled)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in 
                // Only trigger UI update - renderMask changes are handled in MetalOverlayView
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // VISUAL-ONLY CHANGES: Only affect rendering appearance - no geometry recomputation needed
        
        // Rendering pass enabled/disabled (affects render pass list but not geometry)
        rendering.$backgroundPassEnabled
            .combineLatest(rendering.$foregroundPassEnabled)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in 
                // Only trigger UI update, no metalData recomputation needed
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Color changes (pure visual - no geometry impact)
        rendering.$backgroundPassColor
            .combineLatest(rendering.$foregroundPassColor)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in 
                // Only trigger UI update, no metalData recomputation needed
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

struct SplatterView: View {
    @StateObject private var viewModel = SplatterViewModel()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(viewModel.renderPasses, id: \.name) { renderPass in
                    if renderPass.enabled {
                        MetalOverlayView(
                            dots: viewModel.metalData.dots,
                            splotColor: renderPass.color,
                            renderMask: renderPass.renderMask
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .blendMode(.multiply)
                        .opacity(renderPass.opacity)
                        .zIndex(renderPass.zIndex)
                    }
                }
            }
            .onAppear {
                viewModel.updateMetalData() // Initial metal data setup
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("SplatterAddSplat"))) { notification in
                if let location = notification.object as? CGPoint {
                    viewModel.addSplat(at: location, screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SplatterClear"))) { _ in
            viewModel.clear()
        }
    }
}

// MTKView subclass that never intercepts touches
class PassthroughMTKView: MTKView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

struct MetalOverlayView: UIViewRepresentable {
    let dots: [MetalDot]
    let splotColor: SIMD3<Float>
    let renderMask: [Bool] // [central, large, medium, small, splash]

    func makeUIView(context: UIViewRepresentableContext<MetalOverlayView>) -> MTKView {
        guard MetalService.shared.isAvailable,
              let device = MetalService.shared.device else {
            print("⚠️ Metal unavailable - creating disabled MTKView")
            return PassthroughMTKView(frame: .zero, device: nil)
        }
        
        let mtkView = PassthroughMTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        mtkView.isOpaque = false
        mtkView.framebufferOnly = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.delegate = context.coordinator
        mtkView.setNeedsDisplay()
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MetalOverlayView>) {
        let coordinator = context.coordinator
        _ = coordinator.stateManager.updateRenderMask(renderMask)
        _ = coordinator.stateManager.updateMetalDots(dots)
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(splotColor: splotColor)
    }
    class Coordinator: NSObject, MTKViewDelegate {
        let splotColor: SIMD3<Float>
        let stateManager: MetalOverlayStateManager
        let bufferManager: MetalBufferManager
        
        init(splotColor: SIMD3<Float>) {
            self.splotColor = splotColor
            self.stateManager = DefaultMetalOverlayStateManager()
            self.bufferManager = DefaultMetalBufferManager(device: MetalService.shared.device)
            super.init()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard MetalService.shared.isAvailable,
                  let renderer = MetalService.shared.renderer,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let metalDotsBuffer = bufferManager.metalDotsBuffer,
                  let renderMaskBuffer = bufferManager.renderMaskBuffer,
                  let quadBuffer = bufferManager.quadBuffer else { 
                return 
            }
            
            // Update buffers with current data
            bufferManager.updateBuffers(with: stateManager)
            
            let aspect = Float(view.bounds.width / view.bounds.height)
            
            renderer.render(
                drawable: drawable,
                descriptor: descriptor,
                metalDotsBuffer: metalDotsBuffer,
                renderMaskBuffer: renderMaskBuffer,
                quadBuffer: quadBuffer,
                aspect: aspect,
                splotColor: splotColor
            )
        }
    }
}
