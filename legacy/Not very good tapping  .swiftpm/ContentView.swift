import SwiftUI
import MetalKit
import simd

struct ContentView: View {
    var body: some View {
        ZStack {
            VStack {
                Button("Tap Me") {
                    print("Button tapped!")
                }
                .padding()
                Spacer()
            }
            
            MetalViewWrapper()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MetalViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView {
        MetalView(frame: .zero)
    }
    
    func updateUIView(_ uiView: MetalView, context: Context) {}
}

class MetalView: MTKView {
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var tapPoints: [CGPoint] = []
    
    private let metalSource = """
    using namespace metal;
    
    struct Vertex {
        float2 position [[attribute(0)]];
    };
    
    vertex float4 vertex_main(const device Vertex* vertices [[buffer(0)]], uint vid [[vertex_id]]) {
        return float4(vertices[vid].position, 0.0, 1.0);
    }
    
    fragment float4 fragment_main() {
        return float4(1.0, 0.0, 0.0, 1.0); // Red
    }
    """
    
    required init(frame: CGRect) {
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: frame, device: device)
        
        self.device = device
        self.framebufferOnly = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.commandQueue = device.makeCommandQueue()
        self.colorPixelFormat = .bgra8Unorm
        self.delegate = self
        
        compileShader()
        setupGestureRecognizer()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func compileShader() {
        let library = try! device!.makeLibrary(source: metalSource, options: nil)
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDesc)
    }
    
    private func setupGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        tapPoints.append(location)
    }
    
    private func ndcPoint(from point: CGPoint) -> float2 {
        let x = Float((point.x / bounds.width) * 2 - 1)
        let y = Float((1 - point.y / bounds.height) * 2 - 1)
        return float2(x, y)
    }
    
    private func circleVertices(at center: CGPoint, radius: Float = 0.05, segments: Int = 32) -> [float2] {
        let centerNDC = ndcPoint(from: center)
        var vertices: [float2] = []
        
        for i in 0..<segments {
            let angle1 = Float(i) / Float(segments) * 2 * .pi
            let angle2 = Float(i + 1) / Float(segments) * 2 * .pi
            
            let p0 = centerNDC
            let p1 = float2(centerNDC.x + cos(angle1) * radius, centerNDC.y + sin(angle1) * radius)
            let p2 = float2(centerNDC.x + cos(angle2) * radius, centerNDC.y + sin(angle2) * radius)
            
            vertices.append(contentsOf: [p0, p1, p2])
        }
        
        return vertices
    }
}

extension MetalView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        
        for point in tapPoints {
            let vertices = circleVertices(at: point)
            let buffer = device!.makeBuffer(bytes: vertices,
                                            length: vertices.count * MemoryLayout<float2>.stride,
                                            options: [])
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
