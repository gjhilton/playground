// Version: 2.18
import SwiftUI
import MetalKit
import simd

enum RenderingConstants {
    static let splatDotLimit = 512
}

struct SplatDot: Identifiable, Equatable {
    let id: UUID = UUID()
    let position: CGPoint
    let size: CGSize
    let isEllipse: Bool
    let rotation: Double
}

struct Splat: Identifiable, Equatable {
    let id: UUID = UUID()
    let center: CGPoint
    let dots: [SplatDot]

    struct Parameters {
        let centralRadiusRange: ClosedRange<CGFloat>
        let largeCountRange: ClosedRange<Int>
        let largeRadiusRange: ClosedRange<CGFloat>
        let largeDistanceRange: ClosedRange<CGFloat>
        let mediumCountRange: ClosedRange<Int>
        let mediumRadiusRange: ClosedRange<CGFloat>
        let mediumDistanceRange: ClosedRange<CGFloat>
        let smallCountRange: ClosedRange<Int>
        let smallRadiusRange: ClosedRange<CGFloat>
        let smallDistanceRange: ClosedRange<CGFloat>
        let splashCountRange: ClosedRange<Int>
        let splashLengthRange: ClosedRange<CGFloat>
        let splashWidthRange: ClosedRange<CGFloat>
        let splashDistanceRange: ClosedRange<CGFloat>
        let splashRotationJitter: ClosedRange<Double>
        let splotColor: SIMD3<Float>
    }

    static let params = Parameters(
        centralRadiusRange: 19.375...20.625,
        largeCountRange: 0...3,
        largeRadiusRange: 19.375...20.625,
        largeDistanceRange: 25.0...67.5,
        mediumCountRange: 3...9,
        mediumRadiusRange: 13.625...14.375,
        mediumDistanceRange: 80.0...140.0,
        smallCountRange: 6...15,
        smallRadiusRange: 6.875...8.125,
        smallDistanceRange: 60.0...165.0,
        splashCountRange: 0...6,
        splashLengthRange: 20...60,
        splashWidthRange: 10...30,
        splashDistanceRange: 80.0...140.0,
        splashRotationJitter: -10...10,
        splotColor: SIMD3<Float>(0.55, 0, 0)
    )

    static func generate(center: CGPoint, params: Parameters = Splat.params) -> Splat {
        var dots: [SplatDot] = []
        // Central dot
        let centralRadius = CGFloat.random(in: params.centralRadiusRange) / 10.0
        dots.append(SplatDot(
            position: center,
            size: CGSize(width: centralRadius * 2, height: centralRadius * 2),
            isEllipse: false,
            rotation: 0
        ))
        // Large dots
        let largeCount = Int.random(in: params.largeCountRange)
        for _ in 0..<largeCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.largeDistanceRange)
            let radius = CGFloat.random(in: params.largeRadiusRange) / 10.0
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // Medium dots
        let mediumCount = Int.random(in: params.mediumCountRange)
        for _ in 0..<mediumCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.mediumDistanceRange)
            let radius = CGFloat.random(in: params.mediumRadiusRange) / 10.0
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // Small dots
        let smallCount = Int.random(in: params.smallCountRange)
        for _ in 0..<smallCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.smallDistanceRange)
            let radius = CGFloat.random(in: params.smallRadiusRange) / 10.0
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // Splashes (ellipses)
        let splashCount = Int.random(in: params.splashCountRange)
        for _ in 0..<splashCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.splashDistanceRange)
            let length = CGFloat.random(in: params.splashLengthRange)
            let width = CGFloat.random(in: params.splashWidthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let rotation = Double(angle * 180 / .pi) + Double.random(in: params.splashRotationJitter)
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: width, height: length),
                isEllipse: true,
                rotation: rotation
            ))
        }
        return Splat(center: center, dots: dots)
    }

    private init(center: CGPoint, dots: [SplatDot]) {
        self.center = center
        self.dots = dots
    }
}

class SplatterViewModel: ObservableObject {
    @Published var splats: [Splat] = []
    @Published var overlayDotXs: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    @Published var overlayDotYs: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    @Published var overlayDotRadii: [Float] = Array(repeating: 0, count: RenderingConstants.splatDotLimit)
    
    var allSplatDots: [SplatDot] {
        splats.flatMap { $0.dots }
    }
    var splotColor: SIMD3<Float> { Splat.params.splotColor }
    
    func addSplat(at location: CGPoint) {
        print("👆 SplatterViewModel.addSplat(at:) called at \(location)")
        splats.append(Splat.generate(center: location))
        print("👆 SplatterViewModel.addSplat(at:) - splat added, count now: \(splats.count)")
    }
    
    func clear() {
        print("🧽 SplatterViewModel.clear() called")
        splats.removeAll()
        print("🧽 SplatterViewModel.clear() - splats cleared, count now: \(splats.count)")
    }
    
    func updateMetalData(width: CGFloat, height: CGFloat) {
        print("🔧 SplatterViewModel.updateMetalData() called with size: \(width) x \(height)")
        let allDots = allSplatDots.prefix(RenderingConstants.splatDotLimit)
        let xs = allDots.map { Float($0.position.x / width) } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - allDots.count))
        let ys = allDots.map { 1 - Float($0.position.y / height) } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - allDots.count))
        let radii = allDots.map { Float($0.size.width / 2) } + Array(repeating: 0, count: max(0, RenderingConstants.splatDotLimit - allDots.count))
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
            MetalOverlayView(xs: viewModel.overlayDotXs, ys: viewModel.overlayDotYs, radii: viewModel.overlayDotRadii, splotColor: viewModel.splotColor)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.multiply)
                .onChange(of: viewModel.splats) {
                    print("🔄 SplatterView.onChange(of: splats) triggered")
                    viewModel.updateMetalData(width: geo.size.width, height: geo.size.height)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SplatterAddSplat"))) { notification in
            if let location = notification.object as? CGPoint {
                viewModel.addSplat(at: location)
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
                    float radius = radii[i] / 200.0;
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