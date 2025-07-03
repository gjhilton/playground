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
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class StripeImageView: UIView {
    
    var image: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        generateStripeImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func generateStripeImage() {
        let size = CGSize(width: 4000, height: 1000)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        let stripeHeight: CGFloat = 50
        var xPosition: CGFloat = 0
        var isBlue = true
        
        while xPosition < size.width {
            let color: UIColor = isBlue ? .blue : UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0)
            color.setFill()
            let rect = CGRect(x: xPosition, y: 0, width: stripeHeight, height: size.height)
            context?.fill(rect)
            xPosition += stripeHeight
            isBlue.toggle()
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.frame = self.bounds
            addSubview(imageView)
        }
    }
}
