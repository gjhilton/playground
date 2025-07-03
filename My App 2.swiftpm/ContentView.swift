import SwiftUI
import AVKit
import AVFoundation
import CoreImage

// Custom Video Player UIView
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
        
        // Create AVPlayerItemVideoOutput to capture video frames
        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ])
        self.player.currentItem?.add(self.videoOutput)
        
        // Create a display layer for rendering processed frames
        self.displayLayer = CALayer()
        self.layer.addSublayer(displayLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the player and display layers adjust to the view size
        playerLayer.frame = bounds
        displayLayer.frame = bounds
    }
    
    // Function to extract video frames and process them
    func processPixelBuffer() {
        // Capture the current video frame as a pixel buffer
        guard let currentPixelBuffer = videoOutput.copyPixelBuffer(forItemTime: player.currentTime(), itemTimeForDisplay: nil) else {
            print("Failed to capture pixel buffer")
            return
        }
        
        // Process and transform the pixel buffer (zoom, crop, and apply color transformation)
        processAndRenderPixelBuffer(currentPixelBuffer)
    }
    
    // Function to apply transformation (zoom, crop) and set all pixels to red
    func processAndRenderPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // Get the video size and screen size
        guard let asset = player.currentItem?.asset else { return }
        let videoSize = asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize(width: 1, height: 1)
        let screenHeight = bounds.height
        let screenWidth = bounds.width
        
        // Calculate the scale factor to fit the video height
        let scaleFactor = screenHeight / videoSize.height
        
        // Apply scaling transformation to fill the screen height
        let scaledWidth = videoSize.width * scaleFactor
        
        // Calculate the excess width (this is the part we crop)
        let excessWidth = scaledWidth - screenWidth
        let translationX = -excessWidth  // Translate left to show the leftmost part
        
        // Create a CIImage from the pixel buffer
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply the transformation (zoom and crop)
        let transform = CGAffineTransform(translationX: translationX, y: 0).scaledBy(x: scaleFactor, y: scaleFactor)
        let transformedImage = image.transformed(by: transform)
        
        // Convert the transformed image to a red image (set all pixels to red)
        let redImage = transformedImage.applyingFilter("CIConstantColorGenerator", parameters: ["inputColor": CIColor(red: 1.0, green: 0.0, blue: 0.0)])
        
        // Create a new pixel buffer to render the transformed red image
        var outputPixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        let status = CVPixelBufferCreate(nil, Int(screenWidth), Int(screenHeight), kCVPixelFormatType_32BGRA, pixelBufferAttributes as CFDictionary, &outputPixelBuffer)
        
        if status != kCVReturnSuccess || outputPixelBuffer == nil {
            print("Failed to create output pixel buffer")
            return
        }
        
        // Render the red image into the new pixel buffer
        let context = CIContext()
        context.render(redImage, to: outputPixelBuffer!)
        
        // Set the output pixel buffer to the display layer
        DispatchQueue.main.async {
            self.displayLayer.contents = outputPixelBuffer
        }
    }
}

// SwiftUI View to display the video
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
                PlayerUIViewWrapper(playerUIView: playerUIView)
                    .onAppear {
                        // Auto-play the video when the view appears
                        player.play()
                    }
                    .onChange(of: player.currentTime()) { _ in
                        // Process and render the video frames
                        playerUIView.processPixelBuffer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .edgesIgnoringSafeArea(.all) // Allow the video to go under system UI
    }
}

// Wrap the custom UIView inside a SwiftUI view
struct PlayerUIViewWrapper: UIViewRepresentable {
    let playerUIView: VideoPlayerUIView
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        return playerUIView
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        // Update the player view if necessary
    }
}

// Main Content View
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
