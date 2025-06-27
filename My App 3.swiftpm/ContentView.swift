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
        float3 blueCol;
        float3 pinkCol;
        float3 cyanCol;
        float3 greenCol;
        float3 redCol; // Add red color for the new square
        #pragma body
        
        // Fill the texture with a white background
        _output.color.rgb = float3(1.0, 1.0, 1.0);  // White background
        
        // Use UV coordinates of the surface
        float2 uv = _surface.diffuseTexcoord;
        
        // Define the size of the squares (flush to edges)
        float squareSize = 0.1;  // Square size
        
        // Blue square flush to the left
        if (uv.x < squareSize && uv.y > 0.5 - squareSize / 2.0 && uv.y < 0.5 + squareSize / 2.0) {
            _output.color.rgb = blueCol;  // Blue color for the square
        }
        
        // Pink square flush to the right
        if (uv.x > 1.0 - squareSize && uv.y > 0.5 - squareSize / 2.0 && uv.y < 0.5 + squareSize / 2.0) {
            _output.color.rgb = pinkCol;  // Pink color for the square
        }
        
        // Cyan square flush to the top
        if (uv.y > 1.0 - squareSize && uv.x > 0.5 - squareSize / 2.0 && uv.x < 0.5 + squareSize / 2.0) {
            _output.color.rgb = cyanCol;  // Cyan color for the square
        }
        
        // Green square flush to the bottom
        if (uv.y < squareSize && uv.x > 0.5 - squareSize / 2.0 && uv.x < 0.5 + squareSize / 2.0) {
            _output.color.rgb = greenCol;  // Green color for the square
        }
        
        // Red square at a random location
        if (uv.x > redCol.x - squareSize / 2.0 && uv.x < redCol.x + squareSize / 2.0 &&
            uv.y > redCol.y - squareSize / 2.0 && uv.y < redCol.y + squareSize / 2.0) {
            _output.color.rgb = float3(1.0, 0.0, 0.0);  // Red color for the square (255, 0, 0)
        }
        """
        material.shaderModifiers = [.fragment: fragShader]
        
        // Pass the colors to the shader
        material.setValue(SCNVector3(0.0, 0.0, 1.0), forKey: "blueCol")  // Blue color
        material.setValue(SCNVector3(1.0, 0.0, 1.0), forKey: "pinkCol")  // Pink color
        material.setValue(SCNVector3(0.0, 1.0, 1.0), forKey: "cyanCol")  // Cyan color
        material.setValue(SCNVector3(0.0, 1.0, 0.0), forKey: "greenCol")  // Green color
        
        // Generate random position for the red square (within the plane)
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
