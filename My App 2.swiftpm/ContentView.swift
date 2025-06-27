import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var cameraAngle: Float = 0 // Camera rotation angle (around Y axis)
    @State private var verticalAngle: Float = 0.5 // Vertical rotation angle (from horizontal plane)
    
    @State private var lastDragValue: CGFloat = 0 // For drag tracking
    
    let dist: Float = 2.0 // Orbit radius (fixed)
    let centerOfInterest: SIMD3<Float> = [0, 0, 0] // The center of orbit
    let dragSensitivity: Float = 0.00025 // VERY slow sensitivity for the horizontal drag
    let verticalDragSensitivity: Float = 0.000025 // MUCH slower sensitivity for vertical drag
    let minY: Float = 0.25 // Minimum allowed y value (camera height)
    
    var body: some View {
        RealityView { content in
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
            
            // Calculate the camera's position using spherical coordinates
            let x = dist * cos(verticalAngle) * cos(cameraAngle)
            let y = dist * sin(verticalAngle)
            let z = dist * cos(verticalAngle) * sin(cameraAngle)
            
            let cameraPosition = SIMD3<Float>(x, y, z)
            
            // Update camera position
            camera.position = cameraPosition
            camera.look(at: centerOfInterest, from: cameraPosition, relativeTo: nil)
            
            // Position light above the camera
            let lightPos = cameraPosition + SIMD3<Float>(0, 1, 0)
            light.position = lightPos
            light.look(at: centerOfInterest, from: lightPos, relativeTo: nil)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Horizontal drag (left-right)
                    let horizontalDragAmount = Float(value.translation.width)
                    cameraAngle -= horizontalDragAmount * dragSensitivity
                    
                    // Vertical drag (up-down) - this should control the vertical angle of orbit
                    let verticalDragAmount = Float(value.translation.height)
                    verticalAngle -= verticalDragAmount * verticalDragSensitivity
                    
                    // Constrain vertical angle between 0.25 and 1.5 radians to avoid flipping
                    verticalAngle = min(max(verticalAngle, 0.25), 1.5)
                }
        )
    }
}
