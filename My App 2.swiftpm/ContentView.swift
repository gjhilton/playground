
import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        RealityView { content in
            let centerOfInterest: SIMD3<Float> = [0, 0, 0]
            
            guard let uiImage = UIImage(named: "map"),
                  let cgImage = uiImage.cgImage else {
                print("Failed to load map.png from asset catalog")
                return
            }
            
            let texture = try? TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color)
            )
            
            var material = SimpleMaterial()
            if let texture = texture {
                material.baseColor = .texture(texture)
            } else {
                material.baseColor = .color(.white)
                print("Using fallback white color")
            }
            
            let mesh = MeshResource.generatePlane(width: 3.0, depth: 3.0)
            let plane = ModelEntity(mesh: mesh, materials: [material])
            plane.position = centerOfInterest
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(plane)
            
            let camera = PerspectiveCamera()
            camera.position = [0, 1, 2]
            camera.look(at: centerOfInterest, from: camera.position, relativeTo: nil)
            anchor.addChild(camera)
            
            let light = DirectionalLight()
            light.light.intensity = 1000
            light.light.color = .white
            light.position = [0, 2, 2]
            light.look(at: centerOfInterest, from: light.position, relativeTo: nil)
            anchor.addChild(light)
            
            content.add(anchor)
        }
    }
}
