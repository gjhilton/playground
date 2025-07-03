import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

class StripeImageViewModel: ObservableObject {
    @Published var generatedImage: CGImage?
    
    func generateStripeImage(frame: CGRect) {
        let size = frame.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let stripeHeight: CGFloat = 50
        var xPosition: CGFloat = 0
        var isBlue = true
        var isFirstStripe = true
        
        while xPosition < size.width {
            let color: UIColor
            if isFirstStripe {
                color = .green
                isFirstStripe = false
            } else {
                color = isBlue ? .blue : UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0)
            }
            
            color.setFill()
            let rect = CGRect(x: xPosition, y: 0, width: stripeHeight, height: size.height)
            context.fill(rect)
            xPosition += stripeHeight
            isBlue.toggle()
        }
        
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return
        }
        
        UIGraphicsEndImageContext()
        generatedImage = cgImage
    }
    
    func saveImageToCameraRoll() {
        guard let generatedImage = generatedImage else { return }
        let image = UIImage(cgImage: generatedImage)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct ContentView: View {
    @StateObject var viewModel = StripeImageViewModel()
    
    var body: some View {
        ZStack {
            ScrollView(.horizontal) {
                StripeImageViewRepresentable(viewModel: viewModel)
                    .frame(width: 300, height: 170)
            }
            .frame(height: 170)
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        viewModel.saveImageToCameraRoll()
                    }) {
                        Text("Save Image to Camera Roll")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.generateStripeImage(frame: CGRect(x: 0, y: 0, width: 3000, height: 1700))
        }
    }
}

struct StripeImageViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: StripeImageViewModel
    
    func makeUIView(context: Context) -> UIView {
        return StripeImageView(viewModel: viewModel, frame: CGRect(x: 0, y: 0, width: 3000, height: 1700))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let generatedImage = viewModel.generatedImage {
            uiView.layer.contents = generatedImage
        }
    }
}

class StripeImageView: UIView {
    
    @ObservedObject var viewModel: StripeImageViewModel
    private var imageLayer: CALayer!
    private var videoLayer: AVPlayerLayer!
    
    init(viewModel: StripeImageViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        self.backgroundColor = .white
        
        imageLayer = CALayer()
        imageLayer.frame = CGRect(x: 0, y: 0, width: 3000, height: 1700)
        self.layer.addSublayer(imageLayer)
        
        videoLayer = AVPlayerLayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: 3000, height: 1700)
        self.layer.addSublayer(videoLayer)
        
        viewModel.generateStripeImage(frame: frame)
        
        loadAndPlayVideo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let generatedImage = viewModel.generatedImage {
            let scaledImage = scaleImage(image: generatedImage, to: bounds.size)
            imageLayer.contents = scaledImage
        }
    }
    
    private func scaleImage(image: CGImage, to size: CGSize) -> CGImage {
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0, space: image.colorSpace!, bitmapInfo: image.bitmapInfo.rawValue)
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        return context!.makeImage()!
    }
    
    private func loadAndPlayVideo() {
        guard let url = Bundle.main.url(forResource: "example", withExtension: "MP4") else {
            print("Video not found!")
            return
        }
        
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .video).first
        let size = track?.naturalSize ?? CGSize.zero
        print("Video size: \(size.width) x \(size.height)")
        
        let player = AVPlayer(url: url)
        videoLayer.player = player
        player.play()
    }
}
