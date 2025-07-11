import SwiftUI
import UIKit
import AVFoundation

class VideoLayerView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoSize: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupVideo()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVideo()
    }
    
    private func setupVideo() {
        guard let videoURL = Bundle.main.url(forResource: "example", withExtension: "MP4") else {
            print("Could not find example.MP4 in bundle")
            return
        }
        
        let asset = AVURLAsset(url: videoURL)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        playerLayer = AVPlayerLayer(player: player)
        
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let videoTrack = tracks.first {
                    let size = try await videoTrack.load(.naturalSize)
                    await MainActor.run {
                        self.videoSize = size
                        self.updateVideoLayout()
                    }
                }
            } catch {
                print("Error loading video dimensions: \(error)")
            }
        }
        
        playerLayer?.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer!)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        player?.play()
    }
    
    @objc private func playerDidFinishPlaying() {
        print("Video finished playing")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateVideoLayout()
    }
    
    private func updateVideoLayout() {
        guard let playerLayer = playerLayer, videoSize.width > 0, videoSize.height > 0 else { return }
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let videoAspectRatio = videoSize.width / videoSize.height
        let viewAspectRatio = viewWidth / viewHeight
        
        var videoWidth: CGFloat
        var videoHeight: CGFloat
        
        if videoAspectRatio > viewAspectRatio {
            videoHeight = viewHeight
            videoWidth = viewHeight * videoAspectRatio
        } else {
            videoWidth = viewWidth
            videoHeight = viewWidth / videoAspectRatio
        }
        
        playerLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: videoWidth,
            height: videoHeight
        )
    }
    
    func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class SequenceView: UIView {
    private var videoLayerView: VideoLayerView!
    private var currentOrientation: UIDeviceOrientation = .unknown
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        
        videoLayerView = VideoLayerView()
        videoLayerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(videoLayerView)
        
        NSLayoutConstraint.activate([
            videoLayerView.topAnchor.constraint(equalTo: topAnchor),
            videoLayerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoLayerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoLayerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        currentOrientation = UIDevice.current.orientation
    }
    
    @objc private func orientationDidChange() {
        let newOrientation = UIDevice.current.orientation
        
        if newOrientation != currentOrientation && newOrientation != .unknown {
            currentOrientation = newOrientation
            
            DispatchQueue.main.async { [weak self] in
                self?.videoLayerView.restartVideo()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct SequenceViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> SequenceView {
        return SequenceView()
    }
    
    func updateUIView(_ uiView: SequenceView, context: Context) {
    }
}

struct ContentView: View {
    var body: some View {
        SequenceViewWrapper()
            .ignoresSafeArea()
    }
}

