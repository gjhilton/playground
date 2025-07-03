import SwiftUI
import UIKit
import QuartzCore

// ViewModel to manage image creation and saving
class StripeImageViewModel: ObservableObject {
    @Published var generatedImage: CGImage?
    
    func generateStripeImage(frame: CGRect) {
        let size = frame.size
        
        // Create a context to draw the stripes in
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let stripeHeight: CGFloat = 50
        var xPosition: CGFloat = 0
        var isBlue = true
        var isFirstStripe = true  // Flag to track the first stripe
        
        // Create alternating stripes
        while xPosition < size.width {
            let color: UIColor
            
            if isFirstStripe {
                color = .green  // Make the first stripe green
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
        
        // Create a CGImage from the current context
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return
        }
        
        UIGraphicsEndImageContext()
        
        // Save the generated image for later use
        generatedImage = cgImage
    }
    
    // Function to save the image to the camera roll
    func saveImageToCameraRoll() {
        guard let generatedImage = generatedImage else { return }
        
        // Convert CGImage to UIImage
        let image = UIImage(cgImage: generatedImage)
        
        // Save the image to the camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct ContentView: View {
    @StateObject var viewModel = StripeImageViewModel()
    
    var body: some View {
        ZStack {
            // Scrollable image
            ScrollView(.horizontal) {  // Horizontal scrolling for the image
                StripeImageViewRepresentable(viewModel: viewModel)
                    .frame(width: 4000, height: 1000)  // Keep the large size
            }
            .frame(height: 300) // Limit the visible height of the image
            
            // Button on top of the image
            VStack {
                Spacer()
                Button(action: {
                    // Action to save the image
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
        .onAppear {
            // Generate the stripe image when the view appears
            viewModel.generateStripeImage(frame: CGRect(x: 0, y: 0, width: 4000, height: 1000))
        }
    }
}

struct StripeImageViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: StripeImageViewModel
    
    func makeUIView(context: Context) -> UIView {
        return StripeImageView(viewModel: viewModel, frame: CGRect(x: 0, y: 0, width: 4000, height: 1000))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No need to update for now
    }
}

class StripeImageView: UIView {
    
    @ObservedObject var viewModel: StripeImageViewModel
    
    private var imageLayer: CALayer!
    
    init(viewModel: StripeImageViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        self.backgroundColor = .white
        
        // Create a CALayer to hold the image
        imageLayer = CALayer()
        imageLayer.frame = CGRect(x: 0, y: 0, width: 4000, height: 1000)
        
        // Add the layer to the view's layer
        self.layer.addSublayer(imageLayer)
        
        // Generate image once it's initialized
        viewModel.generateStripeImage(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Update the CALayer with the generated image
        if let generatedImage = viewModel.generatedImage {
            imageLayer.contents = generatedImage
        }
    }
}
