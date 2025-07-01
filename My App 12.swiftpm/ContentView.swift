import UIKit
import SceneKit
import SwiftUI

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return MapViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class MapViewController: UIViewController {
    private let sceneView = SCNView()
    private let cameraNode = SCNNode()
    private let rootNode = SCNNode()
    
    private var azimuth: Float = 0.0
    private let orbitRadius: Float = 15.0
    private let cameraHeight: Float = 10.0
    private var lastPanLocation = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScene()
        setupPlane()
        setupCamera()
        setupGestures()
        updateCameraPosition()
    }
    
    private func setupScene() {
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.scene = SCNScene()
        sceneView.scene?.rootNode.addChildNode(rootNode)
        sceneView.backgroundColor = .black
        view.addSubview(sceneView)
    }
    
    private func setupPlane() {
        let plane = SCNPlane(width: 20, height: 20)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "map.png") ?? UIColor.darkGray
        plane.firstMaterial?.isDoubleSided = true
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2  // Rotate to XZ plane
        rootNode.addChildNode(planeNode)
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        cameraNode.camera = camera
        rootNode.addChildNode(cameraNode)
    }
    
    private func updateCameraPosition() {
        // Move camera in circle at constant height
        let x = orbitRadius * cos(azimuth)
        let z = orbitRadius * sin(azimuth)
        let y = cameraHeight
        cameraNode.position = SCNVector3(x, y, z)
        
        // Always look at origin (center of plane)
        cameraNode.look(at: SCNVector3(0, 0, 0))
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(pan)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        let deltaX = Float(translation.x - lastPanLocation.x)
        azimuth -= deltaX * 0.01  // Sensitivity
        updateCameraPosition()
        lastPanLocation = translation
        
        if gesture.state == .ended || gesture.state == .cancelled {
            lastPanLocation = .zero
        }
    }
}
