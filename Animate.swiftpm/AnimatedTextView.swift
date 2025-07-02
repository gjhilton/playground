import AVFoundation
import UIKit
import CoreText

final class AnimatedTextView: UIView {
    // MARK: Properties
    
    private let text: String
    private let fontSize: CGFloat
    private let trackingDuration: CFTimeInterval
    private let opacityDuration: CFTimeInterval
    
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    
    private var currentTracking: CGFloat
    private let trackingRange: ClosedRange<CGFloat> = 10...20
    
    private var currentOpacity: Float
    
    static let debugMode = false // set to false to hide red background
    
    override class var layerClass: AnyClass {
        return CATextLayer.self
    }
    
    private var textLayer: CATextLayer {
        return layer as! CATextLayer
    }
    
    // MARK: Initialization
    
    init(text: String, fontSize: CGFloat, position: CGPoint, trackingDuration: CFTimeInterval = 5, opacityDuration: CFTimeInterval = 2) {
        self.text = text
        self.fontSize = fontSize
        self.trackingDuration = trackingDuration
        self.opacityDuration = opacityDuration
        
        currentTracking = trackingRange.lowerBound
        currentOpacity = 0
        
        let width = Self.calculateWidth(for: text, fontSize: fontSize, tracking: trackingRange.upperBound)
        let height = fontSize * 2
        
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        setupView()
        setupTextLayer()
        center = position
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setupView() {
        backgroundColor = Self.debugMode ? .red : .clear
    }
    
    private func setupTextLayer() {
        textLayer.string = attributedString(for: currentTracking)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = false
        textLayer.truncationMode = .none
        layer.opacity = currentOpacity
    }
    
    // MARK: Attributed String
    
    private func attributedString(for tracking: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .kern: tracking,
            .foregroundColor: UIColor.black.cgColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    // MARK: Animation
    
    func play() {
        animationStartTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func rewind() {
        displayLink?.invalidate()
        displayLink = nil
        currentTracking = trackingRange.lowerBound
        currentOpacity = 0
        textLayer.string = attributedString(for: currentTracking)
        layer.opacity = currentOpacity
    }
    
    @objc private func updateAnimation() {
        let now = CACurrentMediaTime()
        let elapsed = now - animationStartTime
        
        currentOpacity = Float(min(elapsed / opacityDuration, 1))
        layer.opacity = currentOpacity
        
        currentTracking = trackingRange.lowerBound + CGFloat(min(elapsed / trackingDuration, 1)) * (trackingRange.upperBound - trackingRange.lowerBound)
        textLayer.string = attributedString(for: currentTracking)
        
        if elapsed >= trackingDuration {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    // MARK: Helpers
    
    private static func calculateWidth(for text: String, fontSize: CGFloat, tracking: CGFloat) -> CGFloat {
        let attrStr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .kern: tracking
            ]
        )
        
        let line = CTLineCreateWithAttributedString(attrStr as CFAttributedString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        return ceil(lineBounds.width + abs(lineBounds.origin.x)) + 20
    }
}
