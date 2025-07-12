// Version: 2.39
import SwiftUI
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

// MARK: - Data Structures

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
    
    init(from dots: [SplatDot], limit: Int) {
        let limitedDots = Array(dots.prefix(limit))
        let paddingCount = max(0, limit - limitedDots.count)
        
        self.xs = limitedDots.map { Float($0.position.x) } + Array(repeating: 0, count: paddingCount)
        self.ys = limitedDots.map { 1 - Float($0.position.y) } + Array(repeating: 0, count: paddingCount) // Y-flip: SwiftUI → Metal
        self.radii = limitedDots.map { $0.radius } + Array(repeating: 0, count: paddingCount)
        self.types = limitedDots.map { $0.type.rawValue } + Array(repeating: 0, count: paddingCount)
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
            renderMask: [true, false, false, false, false], // only central
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
        vertex VertexOut vertex_main(const device Vertex* vertices [[buffer(0)]], uint vid [[vertex_id]]) {
            VertexOut out;
            out.position = float4(vertices[vid].position, 0.0, 1.0);
            out.uv = (vertices[vid].position + 1.0) * 0.5;
            return out;
        }
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                      constant float* xs [[buffer(1)]],
                                      constant float* ys [[buffer(2)]],
                                      constant float* radii [[buffer(3)]],
                                      constant int* types [[buffer(4)]],
                                      constant float& aspect [[buffer(5)]],
                                      constant float3& splotColor [[buffer(6)]],
                                      constant bool* renderMask [[buffer(7)]]) {
            float2 uv = in.uv;
            float field = 0.0;
            for (uint i = 0; i < SPLAT_DOT_LIMIT; ++i) {
                int dotType = types[i];
                if (dotType < \(RenderingConstants.dotTypeCount) && renderMask[dotType]) {
                    float2 center = float2(xs[i], ys[i]);
                    float2 aspect_uv = float2((uv.x - center.x) * aspect, uv.y - center.y);
                    float radius = radii[i];
                    float dist = length(aspect_uv);
                    field += (radius * radius) / (dist * dist + \(RenderingConstants.metalDistanceEpsilon));
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


    static func generate(center: CGPoint, centralDot: CentralDotParams, largeDots: LargeDotParams, mediumDots: MediumDotParams, smallDots: SmallDotParams, splashes: SplashParams, rendering: RenderingParams, screenWidth: CGFloat, screenHeight: CGFloat) -> Splat {
        var dots: [SplatDot] = []
        
        // Central dot (always at center)
        let centralRadius = CGFloat.random(in: centralDot.radiusRange)
        dots.append(SplatDot(
            position: CGPoint(x: center.x / screenWidth, y: center.y / screenHeight),
            radius: Float(centralRadius / screenWidth),
            isEllipse: false,
            rotation: 0,
            type: .central
        ))
        
        // Scattered dots (large, medium, small)
        dots += generateScatteredDots(center: center, params: largeDots, type: .large, screenWidth: screenWidth, screenHeight: screenHeight)
        dots += generateScatteredDots(center: center, params: mediumDots, type: .medium, screenWidth: screenWidth, screenHeight: screenHeight)
        dots += generateScatteredDots(center: center, params: smallDots, type: .small, screenWidth: screenWidth, screenHeight: screenHeight)
        
        // Splashes (ellipses)
        dots += generateSplashes(center: center, params: splashes, screenWidth: screenWidth, screenHeight: screenHeight)
        
        return Splat(center: center, dots: dots)
    }
    
    /// Generates scattered circular dots around the center point
    private static func generateScatteredDots(center: CGPoint, params: ScatteredDotParams, type: SplatDot.DotType, screenWidth: CGFloat, screenHeight: CGFloat) -> [SplatDot] {
        let count = Int.random(in: params.countRange)
        return (0..<count).map { _ in
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.distanceRange)
            let radius = CGFloat.random(in: params.radiusRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            return SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(radius / screenWidth),
                isEllipse: false,
                rotation: 0,
                type: type
            )
        }
    }
    
    /// Generates elliptical splash dots around the center point
    private static func generateSplashes(center: CGPoint, params: SplashParams, screenWidth: CGFloat, screenHeight: CGFloat) -> [SplatDot] {
        let count = Int.random(in: params.countRange)
        return (0..<count).map { _ in
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.distanceRange)
            let width = CGFloat.random(in: params.widthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let rotation = Double(angle * 180 / .pi) + Double.random(in: params.rotationJitterRange)
            return SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(width / screenWidth), // Use width as radius for splash
                isEllipse: true,
                rotation: rotation,
                type: .splash
            )
        }
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
        // Data changes
        $splats
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.updateMetalData() }
            .store(in: &cancellables)
        
        // Enabled state changes - simplified approach
        centralDot.$enabled
            .combineLatest(largeDots.$enabled, mediumDots.$enabled, smallDots.$enabled)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in self?.updateMetalData() }
            .store(in: &cancellables)
        
        // Rendering pass changes
        rendering.$backgroundPassEnabled
            .combineLatest(rendering.$foregroundPassEnabled)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.updateMetalData() }
            .store(in: &cancellables)
        
        // Rendering color changes
        rendering.$backgroundPassColor
            .combineLatest(rendering.$foregroundPassColor)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.updateMetalData() }
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
                            xs: viewModel.metalData.xs,
                            ys: viewModel.metalData.ys,
                            radii: viewModel.metalData.radii,
                            types: viewModel.metalData.types,
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
    let xs: [Float]
    let ys: [Float]
    let radii: [Float]
    let types: [Int]
    let splotColor: SIMD3<Float>
    let renderMask: [Bool] // [central, large, medium, small, splash]

    func makeUIView(context: Context) -> MTKView {
        let device = MetalPipelineManager.shared.getDevice()
        let mtkView = PassthroughMTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        mtkView.isOpaque = false
        mtkView.backgroundColor = .clear
        mtkView.framebufferOnly = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.delegate = context.coordinator
        mtkView.setNeedsDisplay()
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        coordinator.xs = xs
        coordinator.ys = ys
        coordinator.radii = radii
        coordinator.types = types
        coordinator.renderMask = renderMask
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(splotColor: splotColor)
    }
    class Coordinator: NSObject, MTKViewDelegate {
        let splotColor: SIMD3<Float>
        var xs: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
        var ys: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
        var radii: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
        var types: [Int] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
        var renderMask: [Bool] = [true, true, true, true, false]
        
        init(splotColor: SIMD3<Float>) {
            self.splotColor = splotColor
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let pipelineState = MetalPipelineManager.shared.getPipelineState(),
                  let commandQueue = MetalPipelineManager.shared.getCommandQueue() else { return }
            
            var xs = self.xs
            var ys = self.ys
            var radii = self.radii
            var types = self.types
            var aspect = Float(view.bounds.width / view.bounds.height)
            var renderMask = self.renderMask
            
            let quadVertices: [SIMD2<Float>] = [
                SIMD2<Float>(-1, -1),
                SIMD2<Float>(-1,  1),
                SIMD2<Float>( 1, -1),
                SIMD2<Float>( 1, -1),
                SIMD2<Float>(-1,  1),
                SIMD2<Float>( 1,  1)
            ]
            let quadBuffer = view.device!.makeBuffer(bytes: quadVertices, length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count, options: [])
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&xs, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 1)
            encoder.setFragmentBytes(&ys, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 2)
            encoder.setFragmentBytes(&radii, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 3)
            encoder.setFragmentBytes(&types, length: MemoryLayout<Int>.stride * RenderingConstants.splatDotLimit, index: 4)
            encoder.setFragmentBytes(&aspect, length: MemoryLayout<Float>.stride, index: 5)
            var splotColorVar = splotColor
            encoder.setFragmentBytes(&splotColorVar, length: MemoryLayout<SIMD3<Float>>.stride, index: 6)
            encoder.setFragmentBytes(&renderMask, length: MemoryLayout<Bool>.stride * RenderingConstants.dotTypeCount, index: 7)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}