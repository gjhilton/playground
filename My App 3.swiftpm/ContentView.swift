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
        let frame = CGRect(x: 0, y: 0, width: 400, height: 200)
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
        
        // No rotation needed, just position the plane at the origin
        node.position = SCNVector3(0, 0, 0)  // Position the plane at the origin
        sceneView.scene!.rootNode.addChildNode(node)
        
        // Generate a random position in local space (between -1 and 1 for x, z)
        let randomPosition = SCNVector3(
            Float.random(in: -1.0...1.0),
            0,  // Keep Y fixed for a 2D plane
            Float.random(in: -1.0...1.0)
        )
        
        // Create material with the fragment shader
        let material = geo.firstMaterial!
        let fragShader = """
        #pragma transparent
        #pragma arguments
        float3 lazerCol;
        float3 dotPosition;
        #pragma body
        
        // Set a white background
        _output.color.rgb = float3(1.0, 1.0, 1.0);  // White background
        
        // Use UV coordinates of the surface
        float2 uv = _surface.diffuseTexcoord;
        
        // Calculate distance from the random position
        float xDist = abs(uv.x - 0.5);  // Distance from the center in x
        float yDist = abs(uv.y - 0.5);  // Distance from the center in y
        float dist = length(float2(xDist, yDist));
        
        // Define the dot size threshold
        float dotSize = 0.1;
        
        // Render the red dot at the random position
        if (dist < dotSize) {
            _output.color.rgb = lazerCol;  // Render the dot in red
        }
        """
        material.shaderModifiers = [.fragment: fragShader]
        
        // Pass the random position and color to the shader
        material.setValue(SCNVector3(1.0, 0.0, 0.0), forKey: "lazerCol")  // Red color for the dot
        material.setValue(randomPosition, forKey: "dotPosition")
        
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
