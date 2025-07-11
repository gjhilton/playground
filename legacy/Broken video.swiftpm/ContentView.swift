import SwiftUI
import AVFoundation

class CroppedVideoViewModel: ObservableObject {
    @Published var videoSize: CGSize = .zero
    
    func loadVideo(url: URL) {
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .video).first
        let size = track?.naturalSize ?? CGSize.zero
        self.videoSize = size
    }
}

struct ContentView: View {
    @StateObject var viewModel = CroppedVideoViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.videoSize != .zero {
                let aspectRatio = viewModel.videoSize.width / viewModel.videoSize.height
                let screenHeight = UIScreen.main.bounds.height
                let screenWidth = screenHeight * aspectRatio
                
                CroppedVideoRepresentable(viewModel: viewModel)
                    .frame(width: screenWidth, height: screenHeight)
                    .position(x: UIScreen.main.bounds.width / 2, y: screenHeight / 2)
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

struct CroppedVideoRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: CroppedVideoViewModel
    
    func makeUIView(context: Context) -> UIView {
        return CroppedVideo(viewModel: viewModel, frame: CGRect(x: 0, y: 0, width: viewModel.videoSize.width, height: viewModel.videoSize.height))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

class CroppedVideo: UIView {
    
    @ObservedObject var viewModel: CroppedVideoViewModel
    private var videoLayer: AVPlayerLayer!
    
    init(viewModel: CroppedVideoViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        self.backgroundColor = .black

        videoLayer = AVPlayerLayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: viewModel.videoSize.width * 2, height: viewModel.videoSize.height * 2)
        self.layer.addSublayer(videoLayer)
        
        if let url = Bundle.main.url(forResource: "example", withExtension: "MP4") {
            loadAndPlayVideo(url: url)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadAndPlayVideo(url: URL) {
        let player = AVPlayer(url: url)
        videoLayer.player = player
        player.play()
    }
}
