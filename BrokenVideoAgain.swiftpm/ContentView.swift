import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        StripeImageViewRepresentable()
            .frame(width: 4000, height: 1000)
    }
}

struct StripeImageViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return StripeImageView(frame: CGRect(x: 0, y: 0, width: 4000, height: 1000))
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No need to update for now, but you could trigger re-rendering of the stripes here.
    }
}

class StripeImageView: UIView {
    
    var imageLayer: CALayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        generateStripeImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateStripeImage() {
        let size = self.bounds.size
        
        // Create a context to draw the stripes in
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let stripeHeight: CGFloat = 50
        var xPosition: CGFloat = 0
        var isBlue = true
        
        // Create alternating stripes
        while xPosition < size.width {
            let color: UIColor = isBlue ? .blue : UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0)
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
        
        // Create a CALayer to display the image
        if imageLayer == nil {
            imageLayer = CALayer()
            imageLayer.frame = self.bounds
            imageLayer.contentsGravity = .resizeAspectFill // Maintain aspect ratio
            layer.addSublayer(imageLayer)
        }
        
        // Set the image as the layer's contents
        imageLayer.contents = cgImage
    }
}
