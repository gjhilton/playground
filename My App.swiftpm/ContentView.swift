import SwiftUI
import UIKit
import SceneKit

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SceneKitViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class SceneKitViewController: UIViewController {
    
    private let sceneView = SCNView()
    private let planeNode = SCNNode()
    private var currentScale: Float = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sceneView)
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        let plane = SCNPlane(width: 4, height: 4 * (view.bounds.height / view.bounds.width))
        plane.firstMaterial?.diffuse.contents = UIImage(named: "map") // <-- load from asset catalog here
        plane.firstMaterial?.isDoubleSided = true
        
        planeNode.geometry = plane
        scene.rootNode.addChildNode(planeNode)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        
        let rotationSpeed: Float = 0.005
        let xRotation = Float(translation.y) * rotationSpeed
        let yRotation = Float(translation.x) * rotationSpeed
        
        planeNode.eulerAngles.x -= xRotation
        planeNode.eulerAngles.y -= yRotation
        
        gesture.setTranslation(.zero, in: sceneView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed || gesture.state == .ended {
            let scaleChange = Float(gesture.scale)
            let newScale = currentScale * scaleChange
            planeNode.scale = SCNVector3(newScale, newScale, newScale)
            if gesture.state == .ended {
                currentScale = newScale
            }
            gesture.scale = 1.0
        }
    }
}
