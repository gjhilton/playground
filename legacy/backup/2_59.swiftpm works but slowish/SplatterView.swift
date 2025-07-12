// Version: 2.59
import SwiftUI
import UIKit
import MetalKit
import simd
import Combine

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

// MARK: - Data Structures

/// Metal-compatible dot structure for efficient GPU transfer
/// Uses SIMD types for optimal alignment and cache coherence
struct MetalDot: Equatable {
    var position: SIMD2<Float> // (x, y) in Metal coordinate space [0,1]
    var radius: Float // Normalized radius [0,1]
    var type: Int32 // Dot type enum raw value [0-4]
    
    init(position: SIMD2<Float>, radius: Float, type: Int32) {
        self.position = position
        self.radius = radius
        self.type = type
    }
}

/// Encapsulates dot data formatted for Metal shader consumption
/// 
/// **Critical Coordinate Transform**: Y-axis is flipped here!
/// - Input: SplatDot.position.y in SwiftUI space (0=top, increases downward)
/// - Output: ys array in Metal space (0=bottom, increases upward)
/// - Transform: `1 - position.y` converts SwiftUI → Metal coordinate space
struct MetalDotData {
    let xs: [Float] // X coordinates in normalized [0,1] space
    let ys: [Float] // Y coordinates in Metal space [0,1] (bottom-left origin)
    let radii: [Float] // Radii normalized to screen width [0,1]
    let types: [Int] // Dot type enum raw values [0-4]
    
    // New unified structure (not used yet, but populated for future migration)
    let dots: [MetalDot] // Unified array of Metal-compatible dots
    
    init(from dots: [SplatDot], limit: Int) {
        let limitedDots = Array(dots.prefix(limit))
        
        // Keep existing arrays for backward compatibility
        self.xs = Self.padArray(limitedDots.map { Float($0.position.x) }, toLimit: limit, with: 0)
        self.ys = Self.padArray(limitedDots.map { 1 - Float($0.position.y) }, toLimit: limit, with: 0) // Y-flip: SwiftUI → Metal
        self.radii = Self.padArray(limitedDots.map { $0.radius }, toLimit: limit, with: 0)
        self.types = Self.padArray(limitedDots.map { $0.type.rawValue }, toLimit: limit, with: 0)
        
        // Also populate new unified structure
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
    let renderMask: [Bool]
    let zIndex: Double
    let enabled: Bool
    
    static func background(color: SIMD3<Float>, enabled: Bool) -> RenderPass {
        RenderPass(
            name: "Background",
            color: color,
            renderMask: [true, true, true, true, false], // central, large, medium, small, no splash
            zIndex: RenderingConstants.zIndexBackground,
            enabled: enabled
        )
    }
    
    static func foreground(color: SIMD3<Float>, enabled: Bool) -> RenderPass {
        RenderPass(
            name: "Foreground",
            color: color,
            renderMask: [true, true, true, false, false], // central, large, medium
            zIndex: RenderingConstants.zIndexForeground,
            enabled: enabled
        )
    }
}

// MARK: - Metal Pipeline Management

class MetalPipelineManager {
    static let shared = MetalPipelineManager()
    
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private let device: MTLDevice
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        setupPipeline()
    }
    
    private func setupPipeline() {
        let metalSource = """
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
        
        do {
            let library = try device.makeLibrary(source: metalSource, options: nil)
            let vertexFunc = library.makeFunction(name: "vertex_main")
            let fragmentFunc = library.makeFunction(name: "fragment_main")
            
            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertexFunc
            pipelineDesc.fragmentFunction = fragmentFunc
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDesc.colorAttachments[0].isBlendingEnabled = true
            pipelineDesc.colorAttachments[0].rgbBlendOperation = .add
            pipelineDesc.colorAttachments[0].alphaBlendOperation = .add
            pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
            self.commandQueue = device.makeCommandQueue()
        } catch {
            fatalError("Failed to create Metal pipeline: \(error)")
        }
    }
    
    func getPipelineState() -> MTLRenderPipelineState? {
        return pipelineState
    }
    
    func getCommandQueue() -> MTLCommandQueue? {
        return commandQueue
    }
    
    func getDevice() -> MTLDevice {
        return device
    }
}

// MARK: - Constants

enum RenderingConstants {
    static let splatDotLimit = 512
    static let metalThreshold: Float = 0.8
    static let metalThresholdSmoothness: Float = 0.15
    static let metalDistanceEpsilon: Float = 1e-4
    static let reactiveUpdateDebounceMs = 10
    static let dotTypeCount = 5
    static let zIndexBackground = 1.0
    static let zIndexForeground = 2.0
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
        dots.append(SplatDot(
            position: CGPoint(x: center.x / screenWidth, y: center.y / screenHeight),
            radius: Float(centralRadius / screenWidth),
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
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(radius / screenWidth),
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
            let rotation = Double(angle * 180 / .pi) + rng.double(in: params.rotationJitterRange)
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(width / screenWidth), // Use width as radius for splash
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
            .background(color: backgroundColorSIMD, enabled: rendering.backgroundPassEnabled),
            .foreground(color: foregroundColorSIMD, enabled: rendering.foregroundPassEnabled)
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
        let device = MetalPipelineManager.shared.getDevice()
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
        coordinator.renderMask = renderMask
        
        // Update unified data (used by Metal shader) - only if changed
        if coordinator.metalDots != dots {
            coordinator.metalDots = dots
        }
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(splotColor: splotColor)
    }
    class Coordinator: NSObject, MTKViewDelegate {
        let splotColor: SIMD3<Float>
        var renderMask: [Bool] = [true, true, true, true, false]
        
        // Unified data structure used by Metal shader
        var metalDots: [MetalDot] = Array(repeating: MetalDot(position: SIMD2<Float>(0, 0), radius: 0, type: 0), count: RenderingConstants.splatDotLimit)
        
        // Metal buffers for efficient GPU uploads
        private var renderMaskBuffer: MTLBuffer?
        private var quadBuffer: MTLBuffer?
        
        // Unified buffer used by Metal shader
        private var metalDotsBuffer: MTLBuffer?
        
        private var device: MTLDevice
        
        init(splotColor: SIMD3<Float>) {
            self.splotColor = splotColor
            self.device = MetalPipelineManager.shared.getDevice()
            super.init()
            createBuffers()
        }
        
        private func createBuffers() {
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
        
        private func updateBuffers() {
            // Update render mask buffer
            if let buffer = renderMaskBuffer {
                let pointer = buffer.contents().bindMemory(to: Bool.self, capacity: RenderingConstants.dotTypeCount)
                for i in 0..<RenderingConstants.dotTypeCount {
                    pointer[i] = renderMask[i]
                }
            }
            
            // Update unified MetalDot buffer (used by Metal shader) - efficient copy
            if let buffer = metalDotsBuffer {
                let bufferPointer = buffer.contents()
                metalDots.withUnsafeBytes { bytes in
                    bufferPointer.copyMemory(from: bytes.bindMemory(to: UInt8.self).baseAddress!, byteCount: min(bytes.count, buffer.length))
                }
            }
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let pipelineState = MetalPipelineManager.shared.getPipelineState(),
                  let commandQueue = MetalPipelineManager.shared.getCommandQueue(),
                  let metalDotsBuffer = metalDotsBuffer,
                  let renderMaskBuffer = renderMaskBuffer,
                  let quadBuffer = quadBuffer else { return }
            
            // Update buffers with current data
            updateBuffers()
            
            var aspect = Float(view.bounds.width / view.bounds.height)
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
            
            // Use unified MetalDot buffer
            encoder.setFragmentBuffer(metalDotsBuffer, offset: 0, index: 1)
            
            // Keep setFragmentBytes for small, frequently changing data
            encoder.setFragmentBytes(&aspect, length: MemoryLayout<Float>.stride, index: 2)
            var splotColorVar = splotColor
            encoder.setFragmentBytes(&splotColorVar, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)
            encoder.setFragmentBuffer(renderMaskBuffer, offset: 0, index: 4)
            
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}