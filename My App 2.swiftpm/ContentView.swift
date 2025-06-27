import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        RealityView { content in
            // Create a flat white plane
            let mesh = MeshResource.generatePlane(width: 1.0, depth: 1.0)
            let material = SimpleMaterial(color: .white, isMetallic: false)
            let plane = ModelEntity(mesh: mesh, materials: [material])
            plane.position = [0, 0, 0]
            
            // Create an anchor at the world origin
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(plane)
            
            // Add a camera
            let camera = PerspectiveCamera()
            camera.position = [0, 1.0, 2.0]
            camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
            anchor.addChild(camera)
            
            // Add directional light
            let light = DirectionalLight()
            light.light.intensity = 1000
            light.light.color = .white
            light.position = [0, 2, 2]
            light.look(at: [0, 0, 0], from: light.position, relativeTo: nil)
            anchor.addChild(light)
            
            // Add everything to the scene
            content.add(anchor)
        }
    }
}
