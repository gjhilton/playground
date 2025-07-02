import AVFoundation
import UIKit
import CoreText

final class AnimatedTextView: UIView {
    private let text: String
    private let fontSize: CGFloat
    
    init(text: String, fontSize: CGFloat, position: CGPoint) {
        self.text = text
        self.fontSize = fontSize
        let height = fontSize * 2
        let width: CGFloat = 300
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        backgroundColor = .red
        
        center = position
        isOpaque = false
        
        setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Flip the coordinate system because Core Text's origin is bottom-left
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        
        // Create paragraph style with center alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        // Create attributed string with font and paragraph style
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Create framesetter and frame
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)
        
        // Draw the text frame
        CTFrameDraw(frame, context)
    }
    
    func play() {
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
    
    func rewind() {
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
}
