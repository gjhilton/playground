import SwiftUI
import RealityKit

/*
 **ContentView.swift** for RealityKit Camera Orbit
 
 **Purpose**:
 - This SwiftUI view creates a simple RealityKit scene where a plane is placed at the origin and the camera orbits around it based on user interaction (dragging).
 - The camera orbits around the origin in a **spherical coordinate system**. The horizontal drag rotates the camera around the Y-axis, and the vertical drag moves the camera up and down along a semicircular orbit above the plane.
 - The camera maintains a fixed distance from the center and only orbits in 3D space. The drag speed for both axes (horizontal and vertical) has been significantly slowed down for smoother, more controlled interaction.
 
 **Important Notes**:
 - The camera rotates around the origin, staying a fixed distance (`dist`) from the center.
 - The vertical dragging is constrained so that the camera can never move below a certain height (Y ≥ 0.25), ensuring that the camera stays above the plane.
 - Sensitivities for both horizontal and vertical dragging have been adjusted to very slow values for a smooth experience.
 
 **Features**:
 - Horizontal drag (left-right) rotates the camera around the Y-axis (azimuthal rotation).
 - Vertical drag (up-down) moves the camera along a semicircular arc around the origin, modifying its elevation (altitude).
 - Camera position is calculated using spherical coordinates to maintain a fixed distance and smooth movement along the orbit.
 
 **Drag Sensitivity**:
 - Horizontal Drag Sensitivity (`dragSensitivity`) is set to `0.00025` for slower horizontal camera movement.
 - Vertical Drag Sensitivity (`verticalDragSensitivity`) is set to `0.00025` for slower vertical movement.
 
 **Camera Constraints**:
 - The camera’s vertical angle is constrained between 0.25 and 1.5 radians to prevent flipping over or going below the plane.
 
 **To Pick Up From Here**:
 - The drag behavior and camera movement logic are managed via `DragGesture()`, which updates the `cameraAngle` (horizontal rotation) and `verticalAngle` (vertical rotation).
 - The camera position is updated in the `RealityView`'s `update` closure.
 - Further improvements might include adding inertia, smoother transitions, or additional features like zooming or camera pitch adjustments.
 
 **Current Known Limitations**:
 - The camera is always fixed at a distance from the center (`dist`), and no zooming or scaling is implemented yet.
 - Only horizontal and vertical dragging is implemented as an interaction method.
 - The code does not handle edge cases like extreme dragging that might push the camera out of bounds.
 
 */

struct ContentView: View {
    @State private var cameraAngle: Float = 0 // Camera rotation angle (around Y axis)
    @State private var verticalAngle: Float = 0.5 // Vertical rotation angle (from horizontal plane)
    
    @State private var lastDragValue: CGFloat = 0 // For drag tracking
    
    let dist: Float = 2.0 // Orbit radius (fixed)
    let centerOfInterest: SIMD3<Float> = [0, 0, 0] // The center of orbit
    let dragSensitivity: Float = 0.00025 // VERY slow sensitivity for the horizontal drag
    let verticalDragSensitivity: Float = 0.00025 // Slower sensitivity for vertical drag
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
