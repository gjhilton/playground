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
        sceneView.backgroundColor = .black
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.scene = SCNScene()
        
        // Camera node setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 12)
        sceneView.scene!.rootNode.addChildNode(cameraNode)
        
        // Create a geometry (SCNBox) for the 3D object
        let geo = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 0.5)
        let node = SCNNode(geometry: geo)
        node.transform = SCNMatrix4MakeRotation(Float.pi * 0.25, 1, 0, 0)
        sceneView.scene!.rootNode.addChildNode(node)
        
        // Create material with the fragment shader
        let material = geo.firstMaterial!
        let fragShader = """
        #pragma transparent
        #pragma arguments
        float3 lazerCol;
        #pragma body
        float2 uv = _surface.diffuseTexcoord;
        float x = 1.0-sin(uv.x*M_PI_F);
        x = pow(x,4) - 0.05;
        float y = 1.0-sin(uv.y*M_PI_F);
        y = pow(y,4)-0.05;
        
        float mx = mix(x,y,0.5);
        float3 col = lazerCol * mx;
        col *= 4.;
        _output.color.rgb = col;
        """
        material.shaderModifiers = [.fragment: fragShader]
        material.setValue(SCNVector3(0.5, 0.8, 0.5), forKey: "lazerCol")
        
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
