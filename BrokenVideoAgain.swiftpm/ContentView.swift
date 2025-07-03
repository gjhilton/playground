import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

class StripeImageViewModel: ObservableObject {
    @Published var videoSize: CGSize = .zero
    
    func loadVideo(url: URL) {
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .video).first
        let size = track?.naturalSize ?? CGSize.zero
        self.videoSize = size
    }
}

struct ContentView: View {
    @StateObject var viewModel = StripeImageViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.videoSize != .zero {
                // Compute aspect ratio based on video size
                let aspectRatio = viewModel.videoSize.width / viewModel.videoSize.height
                
                // Determine the height and width based on screen height
                let screenHeight = UIScreen.main.bounds.height
                let screenWidth = screenHeight * aspectRatio
                
                // Set the frame size accordingly
                StripeImageViewRepresentable(viewModel: viewModel)
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

struct StripeImageViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: StripeImageViewModel
    
    func makeUIView(context: Context) -> UIView {
        return StripeImageView(viewModel: viewModel, frame: CGRect(x: 0, y: 0, width: viewModel.videoSize.width, height: viewModel.videoSize.height))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed since we're just playing the video
    }
}

class StripeImageView: UIView {
    
    @ObservedObject var viewModel: StripeImageViewModel
    private var videoLayer: AVPlayerLayer!
    
    init(viewModel: StripeImageViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        self.backgroundColor = .black  // Ensure background is black to match the video
        
        videoLayer = AVPlayerLayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: viewModel.videoSize.width, height: viewModel.videoSize.height)
        self.layer.addSublayer(videoLayer)
        
        loadAndPlayVideo(url: Bundle.main.url(forResource: "example", withExtension: "MP4")!)  // Correct case: MP4
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadAndPlayVideo(url: URL) {
        let asset = AVAsset(url: url)
        let player = AVPlayer(url: url)
        videoLayer.player = player
        player.play()
    }
}
