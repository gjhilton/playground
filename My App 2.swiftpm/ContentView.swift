import SwiftUI
import AVKit
import AVFoundation

class VideoPlayerUIView: UIView {
    var playerLayer: AVPlayerLayer!
    var player: AVPlayer!
    var videoOutput: AVPlayerItemVideoOutput!
    var displayLayer: CALayer!
    
    init(player: AVPlayer) {
        self.player = player
        super.init(frame: .zero)
        
        // Create and add player layer to the view
        self.playerLayer = AVPlayerLayer(player: player)
        self.layer.addSublayer(playerLayer)
        
        // Create AVPlayerItemVideoOutput
        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ])
        self.player.currentItem?.add(self.videoOutput)
        
        // Display layer for processed video
        self.displayLayer = CALayer()
        self.layer.addSublayer(displayLayer)
        
        self.playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the player layer and display layer adjust to the size of the view
        playerLayer.frame = bounds
        displayLayer.frame = bounds
    }
    
    func zoomAndCropVideo() {
        // Capture pixel buffer from the AVPlayerItemVideoOutput
        guard let currentPixelBuffer = videoOutput.copyPixelBuffer(forItemTime: player.currentTime(), itemTimeForDisplay: nil) else {
            print("Failed to capture pixel buffer")
            return
        }
        
        // Process the pixel buffer (apply zoom and crop)
        processPixelBuffer(currentPixelBuffer)
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // Get the video asset size (size of the original video)
        guard let asset = player.currentItem?.asset else { return }
        let videoSize = asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize(width: 1, height: 1)
        
        let screenHeight = bounds.height
        let screenWidth = bounds.width
        
        // Calculate scale factor to fit the video height
        let scaleFactor = screenHeight / videoSize.height
        
        // Apply scaling transformation to the video
        let scaledWidth = videoSize.width * scaleFactor
        
        // Calculate the excess width (this will be cropped from the right)
        let excessWidth = scaledWidth - screenWidth
        
        // Set translation to crop the excess width from the right (focus on left side)
        let translationX = -excessWidth  // Translate to the left, crop from the right
        
        // Create a CIImage from the pixel buffer
        let context = CIContext()
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply scaling and translation transformations to the image
        let transform = CGAffineTransform(translationX: translationX, y: 0).scaledBy(x: scaleFactor, y: scaleFactor)
        let transformedImage = image.transformed(by: transform)
        
        // Create a new pixel buffer with the transformed image
        var outputPixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        // Allocate a pixel buffer with a non-optional pointer
        let status = CVPixelBufferCreate(nil, Int(screenWidth), Int(screenHeight), kCVPixelFormatType_32BGRA, pixelBufferAttributes as CFDictionary, &outputPixelBuffer)
        
        if status != kCVReturnSuccess || outputPixelBuffer == nil {
            print("Failed to create pixel buffer")
            return
        }
        
        // Render the transformed image to the output pixel buffer
        context.render(transformedImage, to: outputPixelBuffer!)
        
        // Display the processed pixel buffer in the custom display layer
        displayLayer.contents = outputPixelBuffer
    }
}

struct VideoPlayerView: View {
    private let player: AVPlayer
    private let playerUIView: VideoPlayerUIView
    
    init(videoURL: URL) {
        self.player = AVPlayer(url: videoURL)
        self.playerUIView = VideoPlayerUIView(player: player)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Custom view to display the video
                PlayerUIViewWrapper(playerUIView: playerUIView)
                    .onAppear {
                        // Auto-play the video when the view appears
                        player.play()
                    }
                    .onChange(of: player.currentTime()) { _ in
                        // Apply zoom and crop as the video plays
                        playerUIView.zoomAndCropVideo()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height) // Full screen
            }
        }
        .edgesIgnoringSafeArea(.all) // Allow the video to go under system UI
    }
}

struct PlayerUIViewWrapper: UIViewRepresentable {
    let playerUIView: VideoPlayerUIView
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        return playerUIView
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        // Update the player view when necessary
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            // Assuming your video is named "example.MP4" in the resources folder
            if let videoURL = Bundle.main.url(forResource: "example", withExtension: "MP4") {
                VideoPlayerView(videoURL: videoURL)
            } else {
                Text("Video not found!")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
