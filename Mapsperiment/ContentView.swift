import SwiftUI
import SceneKit

struct ContentView: View {
    @State private var selectedHotspot: Int? = nil
    
    var body: some View {
        NavigationView {
            if let selected = selectedHotspot {
                DetailView(selectedHotspot: selected) {
                    selectedHotspot = nil
                }
            } else {
                MenuView { hotspot in
                    selectedHotspot = hotspot
                }
            }
        }
    }
}

struct MenuView: View {
    var onSelect: (Int) -> Void
    
    var body: some View {
        VStack {
            Text("Map")
                .font(.largeTitle)
            MapSceneView(onSelect: onSelect)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct DetailView: View {
    var selectedHotspot: Int
    var onBack: () -> Void
    
    var body: some View {
        VStack {
            Text("Detail for Hotspot \(selectedHotspot)")
                .font(.title)
            ScrollView {
                Text("""
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.
                """)
                .padding()
            }
            Button("Back") {
                onBack()
            }
            .padding()
        }
    }
}

struct MapSceneView: UIViewRepresentable {
    var onSelect: (Int) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        let plane = SCNPlane(width: 10, height: 10)
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        scene.rootNode.addChildNode(planeNode)
        
        for i in 0..<5 {
            let sphere = SCNSphere(radius: 0.2)
            let node = SCNNode(geometry: sphere)
            node.name = "\(i)"
            node.position = SCNVector3(Float(i * 2 - 4), 0.2, 0)
            scene.rootNode.addChildNode(node)
        }
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject {
        var onSelect: (Int) -> Void
        
        init(onSelect: @escaping (Int) -> Void) {
            self.onSelect = onSelect
        }
        
        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            guard let scnView = gestureRecognize.view as? SCNView else { return }
            let p = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(p, options: [:])
            if let result = hitResults.first, let name = result.node.name, let index = Int(name) {
                onSelect(index)
            }
        }
    }
}
