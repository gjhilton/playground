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
    
    private var initialScale: CGFloat = 1.0
    private var initialPlanePosition = SCNVector3Zero
    private var initialPinchScenePoint = SCNVector3Zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.isUserInteractionEnabled = true
        view.addSubview(sceneView)
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = false
        
        // Orthographic camera setup
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 4
        camera.zNear = 1
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)
        
        // Plane with correct aspect ratio
        let planeWidth: CGFloat = 8
        let planeHeight = planeWidth * (view.bounds.height / view.bounds.width)
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "map")
        plane.firstMaterial?.isDoubleSided = true
        
        planeNode.geometry = plane
        scene.rootNode.addChildNode(planeNode)
        
        planeNode.position = SCNVector3Zero
        planeNode.scale = SCNVector3(1, 1, 1)
        
        // Add gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGesture)
    }
    
    // Helper: Convert 2D view point to 3D scene point on plane z=0
    private func scenePoint(fromViewPoint point: CGPoint) -> SCNVector3? {
        guard let cameraNode = sceneView.pointOfView else { return nil }
        
        // Get ray from camera through the screen point
        let nearPoint = sceneView.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 0))
        let farPoint = sceneView.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 1))
        
        let direction = SCNVector3(
            farPoint.x - nearPoint.x,
            farPoint.y - nearPoint.y,
            farPoint.z - nearPoint.z
        )
        
        // Plane is at z=0 in scene coordinates
        let t = -nearPoint.z / direction.z
        if t < 0 { return nil }
        
        let intersectPoint = SCNVector3(
            nearPoint.x + direction.x * t,
            nearPoint.y + direction.y * t,
            0
        )
        return intersectPoint
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            // Record initial scale & plane position
            initialScale = CGFloat(planeNode.scale.x)
            initialPlanePosition = planeNode.position
            
            // Convert pinch center to scene coordinates on plane
            let pinchLocation = gesture.location(in: sceneView)
            if let scenePt = scenePoint(fromViewPoint: pinchLocation) {
                initialPinchScenePoint = scenePt
            } else {
                initialPinchScenePoint = SCNVector3Zero
            }
            
        case .changed:
            // Calculate new scale, clamped
            var newScale = initialScale * gesture.scale
            newScale = max(0.1, min(newScale, 10))
            
            // Apply scale
            planeNode.scale = SCNVector3(newScale, newScale, newScale)
            
            // Calculate how to move plane so pinch point stays fixed
            
            // Vector from plane position to pinch point before scaling
            let offsetBefore = SCNVector3(
                initialPinchScenePoint.x - initialPlanePosition.x,
                initialPinchScenePoint.y - initialPlanePosition.y,
                0)
            
            // Vector after scaling
            let offsetAfter = SCNVector3(
                offsetBefore.x * Float(newScale / initialScale),
                offsetBefore.y * Float(newScale / initialScale),
                0)
            
            // New plane position moves so pinch point visually stays put:
            // newPosition = pinchPoint - offsetAfter
            planeNode.position = SCNVector3(
                initialPinchScenePoint.x - offsetAfter.x,
                initialPinchScenePoint.y - offsetAfter.y,
                0)
            
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        guard let camera = sceneView.pointOfView?.camera else { return }
        let orthoScale = CGFloat(camera.orthographicScale)
        let viewWidth = sceneView.bounds.width
        
        let deltaX = Float(translation.x * 2 * orthoScale / viewWidth)
        let deltaY = Float(-translation.y * 2 * orthoScale / viewWidth)
        
        planeNode.position.x += deltaX / planeNode.scale.x
        planeNode.position.y += deltaY / planeNode.scale.y
        
        gesture.setTranslation(.zero, in: sceneView)
    }
}
