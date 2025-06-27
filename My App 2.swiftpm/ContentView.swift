import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        RealityView { content in
            // Load image from asset catalog
            guard let uiImage = UIImage(named: "map"),
                  let cgImage = uiImage.cgImage else {
                print("❌ Could not load map.png from asset catalog")
                return
            }
            
            // Create texture with semantic
            let texture = try? TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color)
            )
            
            // Build material
            var material = SimpleMaterial()
            if let texture = texture {
                material.baseColor = .texture(texture)
            } else {
                material.baseColor = .color(.white)
                print("⚠️ Using fallback color")
            }
            
            // Create the plane
            let mesh = MeshResource.generatePlane(width: 1.0, depth: 1.0)
            let plane = ModelEntity(mesh: mesh, materials: [material])
            plane.position = [0, 0, 0]
            
            // Anchor at origin
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(plane)
            
            // Camera
            let camera = PerspectiveCamera()
            camera.position = [0, 1, 2]
            camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
            anchor.addChild(camera)
            
            // Light
            let light = DirectionalLight()
            light.light.intensity = 1000
            light.light.color = .white
            light.position = [0, 2, 2]
            light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
            anchor.addChild(light)
            
            // Add to scene
            content.add(anchor)
        }
    }
}
