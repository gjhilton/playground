import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var cameraAngle: Float = 0
    let dist: Float = 2.0
    let centerOfInterest: SIMD3<Float> = [0, 0, 0]
    
    var body: some View {
        RealityView { content in
            // Load texture
            guard let uiImage = UIImage(named: "map"),
                  let cgImage = uiImage.cgImage,
                  let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            else {
                print("Failed to load texture")
                return
            }
            
            var material = SimpleMaterial()
            material.baseColor = .texture(texture)
            
            let mesh = MeshResource.generatePlane(width: 3.0, depth: 3.0)
            let plane = ModelEntity(mesh: mesh, materials: [material])
            plane.position = centerOfInterest
            
            let anchor = AnchorEntity(world: .zero)
            anchor.name = "mainAnchor"
            anchor.addChild(plane)
            
            // Add camera and light placeholders (we’ll update their transforms later)
            let camera = PerspectiveCamera()
            camera.name = "orbitCamera"
            anchor.addChild(camera)
            
            let light = DirectionalLight()
            light.name = "sunLight"
            anchor.addChild(light)
            
            content.add(anchor)
            
        } update: { content in
            guard let anchor = content.entities.first(where: { $0.name == "mainAnchor" }) as? AnchorEntity,
                  let camera = anchor.findEntity(named: "orbitCamera") as? PerspectiveCamera,
                  let light = anchor.findEntity(named: "sunLight") as? DirectionalLight
            else {
                return
            }
            
            // Compute camera position on the orbit
            let x = dist * cos(cameraAngle)
            let z = dist * sin(cameraAngle)
            let y: Float = 1.0
            let cameraPosition = SIMD3<Float>(x, y, z)
            
            camera.position = cameraPosition
            camera.look(at: centerOfInterest, from: cameraPosition, relativeTo: nil)
            
            // Position light to match camera, just a bit higher
            let lightPos = SIMD3<Float>(x, y + 1, z)
            light.position = lightPos
            light.look(at: centerOfInterest, from: lightPos, relativeTo: nil)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dragAmount = Float(value.translation.width)
                    cameraAngle -= dragAmount * 0.005
                }
        )
    }
}
