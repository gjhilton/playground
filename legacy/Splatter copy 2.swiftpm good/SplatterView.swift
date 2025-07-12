// Version: 2.30
import SwiftUI
import MetalKit
import simd

enum RenderingConstants {
    static let splatDotLimit = 512
}

struct SplatDot: Identifiable, Equatable {
    let id: UUID = UUID()
    let position: CGPoint // Normalized 0-1 coordinates
    let radius: Float // Normalized 0-1 radius
    let isEllipse: Bool
    let rotation: Double
    let type: DotType
    
    enum DotType {
        case central, large, medium, small, splash
    }
}

struct Splat: Identifiable, Equatable {
    let id: UUID = UUID()
    let center: CGPoint
    let dots: [SplatDot]

    static func generate(center: CGPoint, centralDot: CentralDotParams, largeDots: LargeDotParams, mediumDots: MediumDotParams, smallDots: SmallDotParams, splashes: SplashParams, rendering: RenderingParams, screenWidth: CGFloat, screenHeight: CGFloat) -> Splat {
        var dots: [SplatDot] = []
        
        // Central dot
        let centralRadius = CGFloat.random(in: centralDot.radiusRange)
        dots.append(SplatDot(
            position: CGPoint(x: center.x / screenWidth, y: center.y / screenHeight),
            radius: Float(centralRadius / screenWidth),
            isEllipse: false,
            rotation: 0,
            type: .central
        ))
        
        // Large dots
        let largeCount = Int.random(in: largeDots.countRange)
        for _ in 0..<largeCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: largeDots.distanceRange)
            let radius = CGFloat.random(in: largeDots.radiusRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(radius / screenWidth),
                isEllipse: false,
                rotation: 0,
                type: .large
            ))
        }
        
        // Medium dots
        let mediumCount = Int.random(in: mediumDots.countRange)
        for _ in 0..<mediumCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: mediumDots.distanceRange)
            let radius = CGFloat.random(in: mediumDots.radiusRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(radius / screenWidth),
                isEllipse: false,
                rotation: 0,
                type: .medium
            ))
        }
        
        // Small dots
        let smallCount = Int.random(in: smallDots.countRange)
        for _ in 0..<smallCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: smallDots.distanceRange)
            let radius = CGFloat.random(in: smallDots.radiusRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(radius / screenWidth),
                isEllipse: false,
                rotation: 0,
                type: .small
            ))
        }
        
        // Splashes (ellipses) - skip for now since we're only doing circles
        let splashCount = Int.random(in: splashes.countRange)
        for _ in 0..<splashCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: splashes.distanceRange)
            let length = CGFloat.random(in: splashes.lengthRange)
            let width = CGFloat.random(in: splashes.widthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let rotation = Double(angle * 180 / .pi) + Double.random(in: splashes.rotationJitterRange)
            dots.append(SplatDot(
                position: CGPoint(x: pos.x / screenWidth, y: pos.y / screenHeight),
                radius: Float(width / screenWidth), // Use width as radius for splash
                isEllipse: true,
                rotation: rotation,
                type: .splash
            ))
        }
        return Splat(center: center, dots: dots)
    }

    private init(center: CGPoint, dots: [SplatDot]) {
        self.center = center
        self.dots = dots
    }
}

// Parameter classes for GUI-friendly controls (all values in pixels)
class CentralDotParams: ObservableObject {
    @Published var radiusMin: CGFloat = 35.0
    @Published var radiusMax: CGFloat = 45.0
    @Published var enabled: Bool = true
    
    var radiusRange: ClosedRange<CGFloat> { radiusMin...radiusMax }
}

class LargeDotParams: ObservableObject {
    @Published var countMin: Int = 0
    @Published var countMax: Int = 3
    @Published var radiusMin: CGFloat = 35.0
    @Published var radiusMax: CGFloat = 45.0
    @Published var distanceMin: CGFloat = 25.0
    @Published var distanceMax: CGFloat = 67.5
    @Published var enabled: Bool = true
    
    var countRange: ClosedRange<Int> { countMin...countMax }
    var radiusRange: ClosedRange<CGFloat> { radiusMin...radiusMax }
    var distanceRange: ClosedRange<CGFloat> { distanceMin...distanceMax }
}

class MediumDotParams: ObservableObject {
    @Published var countMin: Int = 3
    @Published var countMax: Int = 9
    @Published var radiusMin: CGFloat = 25.0
    @Published var radiusMax: CGFloat = 30.0
    @Published var distanceMin: CGFloat = 80.0
    @Published var distanceMax: CGFloat = 140.0
    @Published var enabled: Bool = true
    
    var countRange: ClosedRange<Int> { countMin...countMax }
    var radiusRange: ClosedRange<CGFloat> { radiusMin...radiusMax }
    var distanceRange: ClosedRange<CGFloat> { distanceMin...distanceMax }
}

class SmallDotParams: ObservableObject {
    @Published var countMin: Int = 6
    @Published var countMax: Int = 15
    @Published var radiusMin: CGFloat = 12.0
    @Published var radiusMax: CGFloat = 18.0
    @Published var distanceMin: CGFloat = 60.0
    @Published var distanceMax: CGFloat = 165.0
    @Published var enabled: Bool = true
    
    var countRange: ClosedRange<Int> { countMin...countMax }
    var radiusRange: ClosedRange<CGFloat> { radiusMin...radiusMax }
    var distanceRange: ClosedRange<CGFloat> { distanceMin...distanceMax }
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
    @Published var splotColorR: Float = 0.55
    @Published var splotColorG: Float = 0.0
    @Published var splotColorB: Float = 0.0
    
    var splotColor: SIMD3<Float> { SIMD3<Float>(splotColorR, splotColorG, splotColorB) }
}

class SplatterViewModel: ObservableObject {
    @Published var splats: [Splat] = []
    @Published var overlayDotXs: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    @Published var overlayDotYs: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    @Published var overlayDotRadii: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    
    // Parameter groups
    @Published var centralDot = CentralDotParams()
    @Published var largeDots = LargeDotParams()
    @Published var mediumDots = MediumDotParams()
    @Published var smallDots = SmallDotParams()
    @Published var splashes = SplashParams()
    @Published var rendering = RenderingParams()
    
    // Computed rendering flags based on parameter enabled state
    var renderCentral: Bool { centralDot.enabled }
    var renderLarge: Bool { largeDots.enabled }
    var renderMedium: Bool { mediumDots.enabled }
    var renderSmall: Bool { smallDots.enabled }
    
    var filteredSplatDots: [SplatDot] {
        var filtered: [SplatDot] = []
        for dot in splats.flatMap({ $0.dots }) {
            switch dot.type {
            case .central: if renderCentral { filtered.append(dot) }
            case .large: if renderLarge { filtered.append(dot) }
            case .medium: if renderMedium { filtered.append(dot) }
            case .small: if renderSmall { filtered.append(dot) }
            case .splash: break // Skip splashes for now
            }
        }
        print("🔍 filteredSplatDots: Found \(filtered.count) dots (C:\(renderCentral) L:\(renderLarge) M:\(renderMedium) S:\(renderSmall))")
        return filtered
    }
    
    var splotColor: SIMD3<Float> { rendering.splotColor }
    
    func addSplat(at location: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) {
        print("👆 SplatterViewModel.addSplat(at:) called at \(location)")
        splats.append(Splat.generate(center: location, centralDot: centralDot, largeDots: largeDots, mediumDots: mediumDots, smallDots: smallDots, splashes: splashes, rendering: rendering, screenWidth: screenWidth, screenHeight: screenHeight))
        print("👆 SplatterViewModel.addSplat(at:) - splat added, count now: \(splats.count)")
    }
    
    func clear() {
        print("🧽 SplatterViewModel.clear() called")
        splats.removeAll()
        print("🧽 SplatterViewModel.clear() - splats cleared, count now: \(splats.count)")
    }
    
    func updateMetalData() {
        print("🔧 SplatterViewModel.updateMetalData() called")
        print("🔧 Total splats: \(splats.count)")
        
        // Background layer - filtered dots based on flags (precomputed coordinates)
        let filteredDots = filteredSplatDots.prefix(RenderingConstants.splatDotLimit)
        print("🔧 Filtered dots count: \(filteredDots.count)")
        
        let xs = filteredDots.map { Float($0.position.x) } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - filteredDots.count))
        let ys = filteredDots.map { 1 - Float($0.position.y) } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - filteredDots.count))
        let radii = filteredDots.map { $0.radius } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - filteredDots.count))
        
        print("🔧 First few xs: \(Array(xs.prefix(3)))")
        print("🔧 First few ys: \(Array(ys.prefix(3)))")
        print("🔧 First few radii: \(Array(radii.prefix(3)))")
        
        overlayDotXs = xs
        overlayDotYs = ys
        overlayDotRadii = radii
        
        print("🔧 SplatterViewModel.updateMetalData() - Metal data updated")
    }
}

struct SplatterView: View {
    @StateObject private var viewModel = SplatterViewModel()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background layer - filtered dots based on flags
                MetalOverlayView(xs: viewModel.overlayDotXs, ys: viewModel.overlayDotYs, radii: viewModel.overlayDotRadii, splotColor: viewModel.splotColor)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .blendMode(.multiply)
            }
            .onChange(of: viewModel.splats) {
                print("🔄 SplatterView.onChange(of: splats) triggered")
                viewModel.updateMetalData()
            }
            .onChange(of: viewModel.centralDot.enabled) {
                print("🔄 SplatterView.onChange(of: centralDot.enabled) triggered")
                viewModel.updateMetalData()
            }
            .onChange(of: viewModel.largeDots.enabled) {
                print("🔄 SplatterView.onChange(of: largeDots.enabled) triggered")
                viewModel.updateMetalData()
            }
            .onChange(of: viewModel.mediumDots.enabled) {
                print("🔄 SplatterView.onChange(of: mediumDots.enabled) triggered")
                viewModel.updateMetalData()
            }
            .onChange(of: viewModel.smallDots.enabled) {
                print("🔄 SplatterView.onChange(of: smallDots.enabled) triggered")
                viewModel.updateMetalData()
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
    let splotColor: SIMD3<Float>

    func makeUIView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
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
        private var pipelineState: MTLRenderPipelineState?
        private var commandQueue: MTLCommandQueue?
        private let metalSource: String
        init(splotColor: SIMD3<Float>) {
            self.splotColor = splotColor
            // Metal shader source with SPLAT_DOT_LIMIT
            self.metalSource = """
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
                                          constant float& aspect [[buffer(4)]],
                                          constant float3& splotColor [[buffer(5)]]) {
                float2 uv = in.uv;
                float field = 0.0;
                for (uint i = 0; i < SPLAT_DOT_LIMIT; ++i) {
                    float2 center = float2(xs[i], ys[i]);
                    float2 aspect_uv = float2((uv.x - center.x) * aspect, uv.y - center.y);
                    float radius = radii[i];
                    float dist = length(aspect_uv);
                    field += (radius * radius) / (dist * dist + 1e-4);
                }
                float threshold = 0.8;
                float alpha = smoothstep(threshold, threshold + 0.15, field);
                return float4(splotColor, alpha);
            }
            """
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }
            var xs = self.xs
            var ys = self.ys
            var radii = self.radii
            var aspect = Float(view.bounds.width / view.bounds.height)
            let quadVertices: [SIMD2<Float>] = [
                SIMD2<Float>(-1, -1),
                SIMD2<Float>(-1,  1),
                SIMD2<Float>( 1, -1),
                SIMD2<Float>( 1, -1),
                SIMD2<Float>(-1,  1),
                SIMD2<Float>( 1,  1)
            ]
            let quadBuffer = view.device!.makeBuffer(bytes: quadVertices, length: MemoryLayout<SIMD2<Float>>.stride * quadVertices.count, options: [])
            if pipelineState == nil {
                // Inject SPLAT_DOT_LIMIT into Metal source
                let source = metalSource.replacingOccurrences(of: "\\(RenderingConstants.splatDotLimit)", with: String(RenderingConstants.splatDotLimit))
                let library = try! view.device!.makeLibrary(source: source, options: nil)
                let vertexFunc = library.makeFunction(name: "vertex_main")
                let fragmentFunc = library.makeFunction(name: "fragment_main")
                let pipelineDesc = MTLRenderPipelineDescriptor()
                pipelineDesc.vertexFunction = vertexFunc
                pipelineDesc.fragmentFunction = fragmentFunc
                pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                pipelineState = try! view.device!.makeRenderPipelineState(descriptor: pipelineDesc)
                commandQueue = view.device!.makeCommandQueue()
            }
            let commandBuffer = commandQueue!.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState!)
            encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&xs, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 1)
            encoder.setFragmentBytes(&ys, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 2)
            encoder.setFragmentBytes(&radii, length: MemoryLayout<Float>.stride * RenderingConstants.splatDotLimit, index: 3)
            encoder.setFragmentBytes(&aspect, length: MemoryLayout<Float>.stride, index: 4)
            var splotColorVar = splotColor
            encoder.setFragmentBytes(&splotColorVar, length: MemoryLayout<SIMD3<Float>>.stride, index: 5)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}