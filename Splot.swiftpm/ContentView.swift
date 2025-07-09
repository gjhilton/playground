// Version: 84
import SwiftUI
import AVFoundation
import MetalKit
import simd

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
    }

    static let params = Parameters(
        centralRadiusRange: 15...25, // halved from 30...50
        largeCountRange: 0...3,
        largeRadiusRange: 15...25,
        largeDistanceRange: 12.5...33.75,
        mediumCountRange: 3...9,
        mediumRadiusRange: 8...19,
        mediumDistanceRange: 40...70,
        smallCountRange: 6...15,
        smallRadiusRange: 5...10,
        smallDistanceRange: 30...82.5,
        splashCountRange: 0...6,
        splashLengthRange: 20...60,
        splashWidthRange: 10...30,
        splashDistanceRange: 40...70,
        splashRotationJitter: -10...10
    )

    static func generate(center: CGPoint, params: Parameters = Splat.params) -> Splat {
        var dots: [SplatDot] = []
        // 1 large central dot
        let centralRadius = CGFloat.random(in: params.centralRadiusRange)
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
            let radius = CGFloat.random(in: params.largeRadiusRange)
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
            let radius = CGFloat.random(in: params.mediumRadiusRange)
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
            let radius = CGFloat.random(in: params.smallRadiusRange)
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
            // Rotate so the ellipse points away from the center (radiates out)
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

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var splats: [Splat] = []
    @State private var overlayColor: SIMD3<Float> = SIMD3<Float>(1, 0, 0)
    @State private var overlayDotXs: [Float] = Array(repeating: 0, count: 512)
    @State private var overlayDotYs: [Float] = Array(repeating: 0, count: 512)
    @State private var overlayDotRadii: [Float] = Array(repeating: 0, count: 512)
    @State private var tapCount: Int = 0

    var allSplatDots: [SplatDot] {
        splats.flatMap { $0.dots }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 24) {
                    Button("Button 1") {
                        playAlertSound()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                    Button("Button 2") {
                        playAlertSound()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                }
                // Visualize splats as blue dots/ellipses (commented out for Metal-only test)
                /*
                ForEach(splats) { splat in
                    ForEach(splat.dots) { dot in
                        if dot.isEllipse {
                            Ellipse()
                                .fill(Color.blue.opacity(1))
                                .frame(width: dot.size.width, height: dot.size.height)
                                .position(dot.position)
                                .rotationEffect(.degrees(dot.rotation))
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(1))
                                .frame(width: dot.size.width, height: dot.size.height)
                                .position(dot.position)
                        }
                    }
                }
                */
                // Metal overlay ON TOP, does not block touches
                MetalOverlayView(xs: overlayDotXs, ys: overlayDotYs, radii: overlayDotRadii)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        splats.append(Splat.generate(center: value.location))
                    }
            )
            .onChange(of: splats) { _ in
                let width = geo.size.width
                let height = geo.size.height
                let allDots = allSplatDots.prefix(512)
                let xs = allDots.map { Float($0.position.x / width) } + Array(repeating: 0, count: max(0, 512 - allDots.count))
                let ys = allDots.map { 1 - Float($0.position.y / height) } + Array(repeating: 0, count: max(0, 512 - allDots.count))
                let radii = allDots.map { Float($0.size.width / 2) } + Array(repeating: 0, count: max(0, 512 - allDots.count))
                print("[MetalOverlay] xs: \(xs), ys: \(ys)")
                print("[MetalOverlay] dot positions: \(allDots.map { $0.position })")
                overlayDotXs = xs
                overlayDotYs = ys
                overlayDotRadii = radii
            }
        }
    }

    private func playAlertSound() {
        guard let systemSoundID = SystemSoundID(exactly: 1005) else { return }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

class PassthroughMTKView: MTKView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil // Never intercept touches
    }
}

struct MetalOverlayView: UIViewRepresentable {
    let xs: [Float]
    let ys: [Float]
    let radii: [Float]
    func makeUIView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = PassthroughMTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0) // fully transparent
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
        if let coordinator = context.coordinator as? Coordinator {
            coordinator.xs = xs
            coordinator.ys = ys
            coordinator.radii = radii
        }
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    class Coordinator: NSObject, MTKViewDelegate {
        var xs: [Float] = Array(repeating: 0, count: 512)
        var ys: [Float] = Array(repeating: 0, count: 512)
        var radii: [Float] = Array(repeating: 0, count: 512)
        private var pipelineState: MTLRenderPipelineState?
        private var commandQueue: MTLCommandQueue?
        private let metalSource = """
        using namespace metal;
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
                                      constant float& aspect [[buffer(4)]]) {
            float2 uv = in.uv;
            float alpha = 0.0;
            for (uint i = 0; i < 512; ++i) {
                float2 center = float2(xs[i], ys[i]);
                float2 aspect_uv = float2((uv.x - center.x) * aspect, uv.y - center.y);
                float radius = radii[i] / 200.0;
                float dist = length(aspect_uv);
                alpha = max(alpha, smoothstep(radius, radius - 0.01, dist));
            }
            return float4(0.2, 0.4, 1.0, alpha);
        }
        """
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
                let library = try! view.device!.makeLibrary(source: metalSource, options: nil)
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
            encoder.setFragmentBytes(&xs, length: MemoryLayout<Float>.stride * 512, index: 1)
            encoder.setFragmentBytes(&ys, length: MemoryLayout<Float>.stride * 512, index: 2)
            encoder.setFragmentBytes(&radii, length: MemoryLayout<Float>.stride * 512, index: 3)
            encoder.setFragmentBytes(&aspect, length: MemoryLayout<Float>.stride, index: 4)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
