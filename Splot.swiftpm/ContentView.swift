// v4o
import SwiftUI
import AVFoundation
import MetalKit
import simd

struct SplatDot: Identifiable {
    let id: UUID = UUID()
    let position: CGPoint
    let size: CGSize
    let isEllipse: Bool
    let rotation: Double
}

struct Splat: Identifiable {
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
        centralRadiusRange: 30...50,
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
                // Visualize splats as blue dots/ellipses
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
                // Metal overlay ON TOP, does not block touches
                MetalOverlayView(splatDots: allSplatDots)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        splats.append(Splat.generate(center: location))
                    }
            )
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
    let splatDots: [SplatDot]
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
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    class Coordinator: NSObject, MTKViewDelegate {
        private var pipelineState: MTLRenderPipelineState?
        private var commandQueue: MTLCommandQueue?
        private let circleSegments = 40
        private let metalSource = """
        using namespace metal;
        struct Vertex {
            float2 position [[attribute(0)]];
        };
        vertex float4 vertex_main(const device Vertex* vertices [[buffer(0)]], uint vid [[vertex_id]]) {
            return float4(vertices[vid].position, 0.0, 1.0);
        }
        fragment float4 fragment_main() {
            return float4(0.0, 0.4, 1.0, 0.7); // Blue
        }
        """
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }
            let device = view.device!
            if pipelineState == nil {
                let library = try! device.makeLibrary(source: metalSource, options: nil)
                let vertexFunc = library.makeFunction(name: "vertex_main")
                let fragmentFunc = library.makeFunction(name: "fragment_main")
                let pipelineDesc = MTLRenderPipelineDescriptor()
                pipelineDesc.vertexFunction = vertexFunc
                pipelineDesc.fragmentFunction = fragmentFunc
                pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
                commandQueue = device.makeCommandQueue()
            }
            let commandBuffer = commandQueue!.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState!)
            // Draw a single circle at center of screen
            let width = Float(view.bounds.width)
            let height = Float(view.bounds.height)
            let center = float2(0, 0) // NDC center
            let radius: Float = 0.2 // NDC units (20% of min dimension)
            var vertices: [float2] = []
            for i in 0..<circleSegments {
                let iDouble = Double(i)
                let segmentsDouble = Double(circleSegments)
                let angle1 = iDouble / segmentsDouble * 2.0 * Double.pi
                let angle2 = (iDouble + 1.0) / segmentsDouble * 2.0 * Double.pi

                let cos1 = cos(angle1)
                let sin1 = sin(angle1)
                let cos2 = cos(angle2)
                let sin2 = sin(angle2)

                let x1 = Float(cos1) * radius
                let y1 = Float(sin1) * radius
                let x2 = Float(cos2) * radius
                let y2 = Float(sin2) * radius

                let p0 = center
                let p1 = float2(center.x + x1, center.y + y1)
                let p2 = float2(center.x + x2, center.y + y2)
                vertices.append(contentsOf: [p0, p1, p2])
            }
            let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<float2>.stride, options: [])
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
