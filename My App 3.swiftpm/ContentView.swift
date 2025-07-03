import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        StripedImageView()
            .frame(width: 400, height: 160) // adjust size to fit screen
    }
}

// UIViewRepresentable to use UIKit (UIImageView) within SwiftUI
struct StripedImageView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIImageView {
        // Create the UIImageView
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = generateStripedImage()  // Assign the generated image
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // If needed, update the imageView here. For static image, no update needed.
    }
    
    func generateStripedImage() -> UIImage {
        // Image size
        let width: CGFloat = 4000
        let height: CGFloat = 1600
        
        // Create a graphics context
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        // Stripe colors
        let colors: [CGColor] = [UIColor.red.cgColor, UIColor.systemIndigo.cgColor]
        
        // Stripe width
        let stripeWidth: CGFloat = 100
        
        // Draw stripes
        for i in 0..<Int(width / stripeWidth) {
            let xPosition = CGFloat(i) * stripeWidth
            let color = colors[i % colors.count]
            context.setFillColor(color)
            context.fill(CGRect(x: xPosition, y: 0, width: stripeWidth, height: height))
        }
        
        // Create the image from the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
