import SwiftUI
import RealityKit
import AVFoundation

struct ContentView: View {
    var body: some View {
        RealityView { content in
            // Create the scene
            let scene = createScene()
            content.add(scene)
        }
        .ignoresSafeArea()
    }
    
    private func createScene() -> Entity {
        let rootEntity = Entity()
        
        // Create plane with video texture
        let planeEntity = createVideoPlane()
        rootEntity.addChild(planeEntity)
        
        // Add lights
        let whiteLight = createPointLight(color: .white, position: SIMD3<Float>(0, 5, 2))
        let redLight = createPointLight(color: .red, position: SIMD3<Float>(2, 3, -1))
        
        rootEntity.addChild(whiteLight)
        rootEntity.addChild(redLight)
        
        return rootEntity
    }
    
    private func createVideoPlane() -> Entity {
        guard let videoURL = Bundle.main.url(forResource: "example", withExtension: "MP4") else {
            print("Could not find video file")
            return Entity()
        }
        
        // Create AVPlayer
        let player = AVPlayer(url: videoURL)
        
        // Get video dimensions
        let asset = AVAsset(url: videoURL)
        let videoTrack = try? asset.tracks(withMediaType: .video).first
        let size = videoTrack?.naturalSize ?? CGSize(width: 1920, height: 1080)
        
        // Create plane mesh with video aspect ratio
        let aspectRatio = Float(size.width / size.height)
        let planeWidth: Float = 2.0
        let planeHeight = planeWidth / aspectRatio
        
        let planeMesh = MeshResource.generatePlane(width: planeWidth, height: planeHeight)
        
        // Create video material
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        // Create plane entity
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [videoMaterial])
        
        // Position plane at origin
        planeEntity.position = SIMD3<Float>(0, 0, 0)
        
        // Start playing video
        player.play()
        
        // When video finishes, it will freeze on last frame
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            // Video will automatically freeze on last frame
        }
        
        return planeEntity
    }
    
    private func createPointLight(color: UIColor, position: SIMD3<Float>) -> Entity {
        let lightEntity = Entity()
        
        // Create point light component
        var lightComponent = PointLightComponent()
        lightComponent.color = color
        lightComponent.intensity = 10000
        lightComponent.attenuationRadius = 20
        
        lightEntity.components[PointLightComponent.self] = lightComponent
        lightEntity.position = position
        
        return lightEntity
    }
}
