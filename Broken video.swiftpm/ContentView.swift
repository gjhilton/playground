import SwiftUI
import AVFoundation
import UIKit

class VideoLayerView: UIView {
    var displayLayer: CALayer!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var output: AVPlayerItemVideoOutput!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.displayLayer = CALayer()
        self.layer.addSublayer(displayLayer)
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.displayLayer = CALayer()
        self.layer.addSublayer(displayLayer)
        setupPlayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the CALayer is the size of the parent view
        displayLayer.frame = bounds
        playerLayer.frame = bounds
    }
    
    func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "example", withExtension: "MP4") else {
            print("Video file not found")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Create video output
        output = AVPlayerItemVideoOutput()
        playerItem.add(output)
        
        // Set up player layer
        playerLayer = AVPlayerLayer(player: player)
        layer.addSublayer(playerLayer)
        
        // Hide the AVPlayerLayer, so only the processed video frame is shown
        playerLayer.isHidden = true
        
        // Start playing
        player.play()
        
        // Set a timer to capture video frames and update the layer
        Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
    }
    
    @objc func updateFrame() {
        guard let currentItem = player.currentItem else { return }
        
        let currentTime = player.currentTime()
        
        // Use CMTime directly for itemTimeForDisplay
        var timing = CMTimeMake(value: 0, timescale: 0) // Initialize a default CMTime
        
        // Check if we have a video frame
        if let pixelBuffer = output.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &timing) {
            processPixelBuffer(pixelBuffer)
        }
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // Convert the pixel buffer to a CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Create a CGImage from the CIImage
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            // Display the frame in the layer
            displayLayer.contents = cgImage
        }
    }
}

struct VideoLayerViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> VideoLayerView {
        return VideoLayerView()
    }
    
    func updateUIView(_ uiView: VideoLayerView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        VideoLayerViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
