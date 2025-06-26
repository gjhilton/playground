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
        
        // Perspective camera setup
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)
        
        // Plane with correct aspect ratio
        let planeWidth: CGFloat = 8
        // Use view aspect ratio to calculate plane height
        let planeHeight = planeWidth * (view.bounds.height / view.bounds.width)
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "map")
        plane.firstMaterial?.isDoubleSided = true
        
        planeNode.geometry = plane
        scene.rootNode.addChildNode(planeNode)
        
        // Rotate plane -50 degrees around x axis
        let rotationAngle = -50.0 * Double.pi / 180.0
        planeNode.eulerAngles.x = Float(rotationAngle)
        
        // Now position plane so bottom edge is 1/3 viewport height from bottom
        
        // Calculate vertical offset:
        // The vertical height of the plane projected on y axis is: planeHeight * cos(rotation)
        // The plane's center y position should be: - (projectedHeight / 2) + offsetFromBottomInSceneUnits
        // We want the bottom edge to be at y = -viewportHeight/3 in scene units.
        
        // First convert viewport height in points to scene units:
        // We know camera is at z=10, and perspective projection,
        // so we'll use an approximate mapping by projecting some points:
        // For simplicity, since the plane width = 8, and covers viewport width,
        // the scene X coordinate spans roughly -4 to +4.
        
        // So view width in points corresponds to 8 scene units.
        // Calculate scene units per screen point:
        let sceneUnitsPerPoint = 8.0 / Double(view.bounds.width)
        let bottomOffsetPoints = Double(view.bounds.height) / 3.0
        let bottomOffsetSceneUnits = bottomOffsetPoints * sceneUnitsPerPoint
        
        // Calculate the projected height of the plane on the y-axis (after rotation)
        let projectedPlaneHeight = Double(planeHeight) * cos(rotationAngle)
        
        // Calculate center y position so that bottom edge is bottomOffsetSceneUnits above bottom
        let centerY = -projectedPlaneHeight / 2 + bottomOffsetSceneUnits
        
        planeNode.position = SCNVector3(0, Float(centerY), 0)
        planeNode.scale = SCNVector3(1, 1, 1)
        
        // Gestures (pinch and pan) remain unchanged...
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGesture)
    }
    
    // Helper functions and gesture handlers below (same as previous)
    
    private func scenePoint(fromViewPoint point: CGPoint) -> SCNVector3? {
        guard let cameraNode = sceneView.pointOfView else { return nil }
        
        let nearPoint = sceneView.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 0))
        let farPoint = sceneView.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 1))
        
        let direction = SCNVector3(
            farPoint.x - nearPoint.x,
            farPoint.y - nearPoint.y,
            farPoint.z - nearPoint.z
        )
        
        let planeTransform = planeNode.worldTransform
        let planeNormal = SCNVector3(
            planeTransform.m31,
            planeTransform.m32,
            planeTransform.m33
        )
        let planePoint = SCNVector3(planeTransform.m41, planeTransform.m42, planeTransform.m43)
        
        let rayOrigin = nearPoint
        let rayDirection = direction
        
        let denom = dotProduct(planeNormal, rayDirection)
        if abs(denom) < 1e-6 { return nil }
        
        let diff = SCNVector3(planePoint.x - rayOrigin.x,
                              planePoint.y - rayOrigin.y,
                              planePoint.z - rayOrigin.z)
        let t = dotProduct(diff, planeNormal) / denom
        if t < 0 { return nil }
        
        let intersect = SCNVector3(
            rayOrigin.x + rayDirection.x * t,
            rayOrigin.y + rayDirection.y * t,
            rayOrigin.z + rayDirection.z * t
        )
        
        return planeNode.convertPosition(intersect, from: nil)
    }
    
    func dotProduct(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialScale = CGFloat(planeNode.scale.x)
            initialPlanePosition = planeNode.position
            
            let pinchLocation = gesture.location(in: sceneView)
            if let scenePt = scenePoint(fromViewPoint: pinchLocation) {
                initialPinchScenePoint = scenePt
            } else {
                initialPinchScenePoint = SCNVector3Zero
            }
            
        case .changed:
            var newScale = initialScale * gesture.scale
            newScale = max(0.1, min(newScale, 10))
            
            planeNode.scale = SCNVector3(newScale, newScale, newScale)
            
            let offsetBefore = SCNVector3(
                initialPinchScenePoint.x - initialPlanePosition.x,
                initialPinchScenePoint.y - initialPlanePosition.y,
                initialPinchScenePoint.z - initialPlanePosition.z
            )
            
            let offsetAfter = SCNVector3(
                offsetBefore.x * Float(newScale / initialScale),
                offsetBefore.y * Float(newScale / initialScale),
                offsetBefore.z * Float(newScale / initialScale)
            )
            
            let newPositionLocal = SCNVector3(
                initialPinchScenePoint.x - offsetAfter.x,
                initialPinchScenePoint.y - offsetAfter.y,
                initialPinchScenePoint.z - offsetAfter.z
            )
            
            planeNode.position = newPositionLocal
            
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: sceneView)
        let sensitivity: Float = 0.01
        
        let deltaX = Float(translation.x) * sensitivity
        let deltaY = Float(-translation.y) * sensitivity
        
        planeNode.localTranslate(by: SCNVector3(deltaX / planeNode.scale.x, deltaY / planeNode.scale.y, 0))
        
        gesture.setTranslation(.zero, in: sceneView)
    }
}
