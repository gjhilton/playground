import SwiftUI
import SceneKit
import Metal

// Create a SwiftUI ContentView with the SceneKit view embedded
struct ContentView: View {
    var body: some View {
        SceneView()
            .edgesIgnoringSafeArea(.all)  // Make sure the scene takes up the full screen
    }
}

// Custom SwiftUI view for SceneKit integration
struct SceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        // Set up the SCNView
        let frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        let sceneView = SCNView(frame: frame)
        sceneView.backgroundColor = .black  // Set the background to black
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.scene = SCNScene()
        
        // Camera node setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)  // Position camera closer to the plane
        cameraNode.look(at: SCNVector3(0, 0, 0))  // Make the camera look at the center of the plane
        sceneView.scene!.rootNode.addChildNode(cameraNode)
        
        // Create a geometry (SCNPlane) for the 3D plane
        let geo = SCNPlane(width: 4, height: 4)  // Plane geometry instead of box
        let node = SCNNode(geometry: geo)
        
        // Position the plane at the origin and keep it flat facing forward
        node.position = SCNVector3(0, 0, 0)  // Position the plane at the origin
        node.eulerAngles = SCNVector3(0, 0, 0) // Ensure plane is not rotated at all
        sceneView.scene!.rootNode.addChildNode(node)
        
        // Create material with the fragment shader
        let material = geo.firstMaterial!
        let fragShader = """
        #pragma transparent
        #pragma arguments
        float3 redCol; // Add red color for the new circle
        #pragma body
        
        // Fill the texture with a white background
        _output.color.rgb = float3(1.0, 1.0, 1.0);  // White background
        
        // Use UV coordinates of the surface
        float2 uv = _surface.diffuseTexcoord;
        
        // Red circle at a random location
        float circleRadius = 0.05;  // Circle radius reduced to half
        
        // Calculate the distance from the center of the circle
        float distX = (uv.x - redCol.x);
        float distY = (uv.y - redCol.y);
        
        // Check if the point is inside the circle (distance from center < radius)
        if (distX * distX + distY * distY <= circleRadius * circleRadius) {
            _output.color.rgb = float3(1.0, 0.0, 0.0);  // Red color for the circle (255, 0, 0)
        }
        """
        material.shaderModifiers = [.fragment: fragShader]
        
        // Pass the colors to the shader
        // Generate random position for the red circle (within the plane)
        let randomX = Float.random(in: 0.1...0.9)
        let randomY = Float.random(in: 0.1...0.9)
        material.setValue(SCNVector3(randomX, randomY, 0.0), forKey: "redCol")  // Red color location
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // This method can be used to update the SCNView if necessary
    }
}

// This is the entry point to display the content in the SwiftUI app
struct PlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
