import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

// ViewModel to manage video loading
class CroppedVideoViewModel: ObservableObject {
    @Published var videoSize: CGSize = .zero
    
    func loadVideo(url: URL) {
        // Get the first video track from the asset
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .video).first
        let size = track?.naturalSize ?? CGSize.zero
        self.videoSize = size
    }
}

// ContentView that displays the video
struct ContentView: View {
    @StateObject var viewModel = CroppedVideoViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.videoSize != .zero {
                // Compute aspect ratio based on video size
                let aspectRatio = viewModel.videoSize.width / viewModel.videoSize.height
                
                // Determine the height and width based on screen height
                let screenHeight = UIScreen.main.bounds.height
                let screenWidth = screenHeight * aspectRatio
                
                // Set the frame size accordingly
                CroppedVideoRepresentable(viewModel: viewModel)
                    .frame(width: screenWidth, height: screenHeight) // Adjust the view to screen size
                    .position(x: UIScreen.main.bounds.width / 2, y: screenHeight / 2) // Center the view on screen
            }
        }
        .onAppear {
            if let url = Bundle.main.url(forResource: "example", withExtension: "MP4") {
                viewModel.loadVideo(url: url)
            } else {
                print("Video not found!")
            }
        }
    }
}

// Representing the UIView in SwiftUI
struct CroppedVideoRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: CroppedVideoViewModel
    
    func makeUIView(context: Context) -> UIView {
        return CroppedVideo(viewModel: viewModel, frame: CGRect(x: 0, y: 0, width: viewModel.videoSize.width, height: viewModel.videoSize.height))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed since we're just playing the video
    }
}

// Custom UIView to display the video
class CroppedVideo: UIView {
    
    @ObservedObject var viewModel: CroppedVideoViewModel
    private var videoLayer: AVPlayerLayer!
    
    init(viewModel: CroppedVideoViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        self.backgroundColor = .black  // Ensure background is black to match the video
        
        // Set up the video layer
        videoLayer = AVPlayerLayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: viewModel.videoSize.width, height: viewModel.videoSize.height)
        self.layer.addSublayer(videoLayer)
        
        // Load and play the video
        if let url = Bundle.main.url(forResource: "example", withExtension: "MP4") {
            loadAndPlayVideo(url: url)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Function to load and play the video
    private func loadAndPlayVideo(url: URL) {
        let player = AVPlayer(url: url)
        videoLayer.player = player
        player.play()
    }
}
