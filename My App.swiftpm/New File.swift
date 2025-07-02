import AVFoundation
import UIKit
import CoreText

final class AnimatedTextView: UIView {
    private let text: String
    private let fontSize: CGFloat
    
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    
    private var currentTracking: CGFloat = 10 // start kerning
    private let trackingStartValue: CGFloat = 10
    private let trackingEndValue: CGFloat = 20
    
    private var currentOpacity: Float = 0 // start invisible
    
    static let debugMode = false // set to false to hide red background
    
    override class var layerClass: AnyClass {
        return CATextLayer.self
    }
    
    private var textLayer: CATextLayer {
        return layer as! CATextLayer
    }
    
    init(text: String, fontSize: CGFloat, position: CGPoint) {
        self.text = text
        self.fontSize = fontSize
        
        // Calculate widest width with max tracking (no wrapping)
        let attrStr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .kern: trackingEndValue
            ]
        )
        
        let line = CTLineCreateWithAttributedString(attrStr as CFAttributedString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        // width includes line width + abs(origin.x) for optical bounds + padding
        let width = ceil(lineBounds.width + abs(lineBounds.origin.x)) + 20
        let height = fontSize * 2
        
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        backgroundColor = AnimatedTextView.debugMode ? .red : .clear
        
        textLayer.string = makeAttributedString(withTracking: trackingStartValue)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = false
        textLayer.truncationMode = .none
        
        layer.opacity = 0
        
        currentTracking = trackingStartValue
        currentOpacity = 0
        
        center = position
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeAttributedString(withTracking tracking: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .kern: tracking,
            .foregroundColor: UIColor.black.cgColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func play() {
        animationStartTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func rewind() {
        displayLink?.invalidate()
        displayLink = nil
        currentTracking = trackingStartValue
        currentOpacity = 0
        textLayer.string = makeAttributedString(withTracking: currentTracking)
        layer.opacity = currentOpacity
    }
    
    @objc private func updateAnimation() {
        let duration: CFTimeInterval = 5 // seconds
        let opacityDuration: CFTimeInterval = 2 // seconds
        let now = CACurrentMediaTime()
        let elapsed = now - animationStartTime
        
        // Animate opacity from 0 to 1 over 2 seconds, linear no easing
        if elapsed < opacityDuration {
            currentOpacity = Float(elapsed / opacityDuration)
        } else {
            currentOpacity = 1
        }
        layer.opacity = currentOpacity
        
        // Animate kerning from trackingStartValue to trackingEndValue over 5 seconds, no easing
        if elapsed < duration {
            let percent = CGFloat(elapsed / duration)
            currentTracking = trackingStartValue + (trackingEndValue - trackingStartValue) * percent
        } else {
            currentTracking = trackingEndValue
            // End animation
            displayLink?.invalidate()
            displayLink = nil
        }
        
        textLayer.string = makeAttributedString(withTracking: currentTracking)
    }
}
