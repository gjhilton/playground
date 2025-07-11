import AVFoundation
import UIKit
import CoreText

// MARK: - Animation Configuration

struct TextAnimationConfiguration {
    let trackingRange: ClosedRange<CGFloat>
    let opacityRange: ClosedRange<Float>
    let scaleRange: ClosedRange<CGFloat>
    let rotationRange: ClosedRange<CGFloat>
    
    static let `default` = TextAnimationConfiguration(
        trackingRange: 10...20,
        opacityRange: 0...1,
        scaleRange: 1...1,
        rotationRange: 0...0
    )
    
    static let dramatic = TextAnimationConfiguration(
        trackingRange: 0...25,
        opacityRange: 0...1,
        scaleRange: 0.8...1.2,
        rotationRange: -0.1...0.1
    )
}

// MARK: - Animation State

struct TextAnimationState {
    let tracking: CGFloat
    let opacity: Float
    let scale: CGFloat
    let rotation: CGFloat
    
    static let initial = TextAnimationState(
        tracking: 0,
        opacity: 0,
        scale: 1,
        rotation: 0
    )
}

// MARK: - Animation Progress

struct AnimationProgress {
    let value: CGFloat // 0.0 to 1.0
    let isComplete: Bool
    
    static let start = AnimationProgress(value: 0, isComplete: false)
    static let complete = AnimationProgress(value: 1, isComplete: true)
}

// MARK: - Text Rendering

protocol TextRenderer {
    func attributedString(for text: String, fontSize: CGFloat, tracking: CGFloat) -> NSAttributedString
    func calculateWidth(for text: String, fontSize: CGFloat, tracking: CGFloat) -> CGFloat
}

struct DefaultTextRenderer: TextRenderer {
    func attributedString(for text: String, fontSize: CGFloat, tracking: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .kern: tracking,
            .foregroundColor: UIColor.black.cgColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func calculateWidth(for text: String, fontSize: CGFloat, tracking: CGFloat) -> CGFloat {
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

// MARK: - Animation Controller

protocol AnimationControllerDelegate: AnyObject {
    func animationDidUpdate(state: TextAnimationState, progress: AnimationProgress)
    func animationDidComplete()
}

final class TextAnimationController {
    private let configuration: TextAnimationConfiguration
    private weak var delegate: AnimationControllerDelegate?
    
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var duration: CFTimeInterval = 5.0
    
    init(configuration: TextAnimationConfiguration, delegate: AnimationControllerDelegate) {
        self.configuration = configuration
        self.delegate = delegate
    }
    
    func startAnimation(duration: CFTimeInterval = 5.0) {
        self.duration = duration
        animationStartTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func reset() {
        stopAnimation()
        let initialState = TextAnimationState(
            tracking: configuration.trackingRange.lowerBound,
            opacity: configuration.opacityRange.lowerBound,
            scale: configuration.scaleRange.lowerBound,
            rotation: configuration.rotationRange.lowerBound
        )
        delegate?.animationDidUpdate(state: initialState, progress: .start)
    }
    
    func setProgress(_ progress: CGFloat) {
        let clampedProgress = max(0, min(1, progress))
        let state = calculateState(for: clampedProgress)
        let animationProgress = AnimationProgress(
            value: clampedProgress,
            isComplete: clampedProgress >= 1.0
        )
        delegate?.animationDidUpdate(state: state, progress: animationProgress)
        
        if clampedProgress >= 1.0 {
            delegate?.animationDidComplete()
        }
    }
    
    @objc private func updateAnimation() {
        let now = CACurrentMediaTime()
        let elapsed = now - animationStartTime
        let progress = CGFloat(min(elapsed / duration, 1))
        
        setProgress(progress)
        
        if progress >= 1.0 {
            stopAnimation()
        }
    }
    
    private func calculateState(for progress: CGFloat) -> TextAnimationState {
        let tracking = configuration.trackingRange.lowerBound + 
            progress * (configuration.trackingRange.upperBound - configuration.trackingRange.lowerBound)
        
        let opacity = configuration.opacityRange.lowerBound + 
            Float(progress) * (configuration.opacityRange.upperBound - configuration.opacityRange.lowerBound)
        
        let scale = configuration.scaleRange.lowerBound + 
            progress * (configuration.scaleRange.upperBound - configuration.scaleRange.lowerBound)
        
        let rotation = configuration.rotationRange.lowerBound + 
            progress * (configuration.rotationRange.upperBound - configuration.rotationRange.lowerBound)
        
        return TextAnimationState(
            tracking: tracking,
            opacity: opacity,
            scale: scale,
            rotation: rotation
        )
    }
}

// MARK: - Animated TextView

final class AnimatedTextView: UIView {
    // MARK: Properties
    
    private let text: String
    private let fontSize: CGFloat
    private let configuration: TextAnimationConfiguration
    private let textRenderer: TextRenderer
    
    private var animationController: TextAnimationController!
    
    private var currentState: TextAnimationState
    
    static let debugMode = false
    
    override class var layerClass: AnyClass {
        return CATextLayer.self
    }
    
    private var textLayer: CATextLayer {
        return layer as! CATextLayer
    }
    
    // MARK: Initialization
    
    init(
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        configuration: TextAnimationConfiguration = .default,
        textRenderer: TextRenderer = DefaultTextRenderer()
    ) {
        self.text = text
        self.fontSize = fontSize
        self.configuration = configuration
        self.textRenderer = textRenderer
        
        self.currentState = TextAnimationState(
            tracking: configuration.trackingRange.lowerBound,
            opacity: configuration.opacityRange.lowerBound,
            scale: configuration.scaleRange.lowerBound,
            rotation: configuration.rotationRange.lowerBound
        )
        
        let width = textRenderer.calculateWidth(for: text, fontSize: fontSize, tracking: configuration.trackingRange.upperBound)
        let height = fontSize * 2
        
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        self.animationController = TextAnimationController(configuration: configuration, delegate: self)
        
        setupView()
        setupTextLayer()
        center = position
        applyState(currentState)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setupView() {
        backgroundColor = Self.debugMode ? .red : .clear
    }
    
    private func setupTextLayer() {
        textLayer.string = textRenderer.attributedString(for: text, fontSize: fontSize, tracking: currentState.tracking)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = false
        textLayer.truncationMode = .none
        textLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    // MARK: Public Interface
    
    func play(duration: CFTimeInterval = 5.0) {
        animationController.startAnimation(duration: duration)
    }
    
    func rewind() {
        animationController.reset()
    }
    
    func setProgress(_ progress: CGFloat) {
        animationController.setProgress(progress)
    }
    
    func setState(_ state: TextAnimationState) {
        applyState(state)
    }
    
    // MARK: CALayer Integration
    
    func addToLayer(_ parentLayer: CALayer) {
        parentLayer.addSublayer(layer)
    }
    
    func removeFromParentLayer() {
        layer.removeFromSuperlayer()
    }
    
    // MARK: Keyframe Support
    
    func setKeyframe(at progress: CGFloat, duration: CFTimeInterval = 0) {
        if duration > 0 {
            // Animate to the keyframe
            let currentProgress = getCurrentProgress()
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            
            let targetState = calculateState(for: progress)
            applyState(targetState)
            
            CATransaction.commit()
        } else {
            // Jump to keyframe immediately
            setProgress(progress)
        }
    }
    
    private func getCurrentProgress() -> CGFloat {
        let trackingProgress = (currentState.tracking - configuration.trackingRange.lowerBound) / 
            (configuration.trackingRange.upperBound - configuration.trackingRange.lowerBound)
        return max(0, min(1, trackingProgress))
    }
    
    private func calculateState(for progress: CGFloat) -> TextAnimationState {
        let tracking = configuration.trackingRange.lowerBound + 
            progress * (configuration.trackingRange.upperBound - configuration.trackingRange.lowerBound)
        
        let opacity = configuration.opacityRange.lowerBound + 
            Float(progress) * (configuration.opacityRange.upperBound - configuration.opacityRange.lowerBound)
        
        let scale = configuration.scaleRange.lowerBound + 
            progress * (configuration.scaleRange.upperBound - configuration.scaleRange.lowerBound)
        
        let rotation = configuration.rotationRange.lowerBound + 
            progress * (configuration.rotationRange.upperBound - configuration.rotationRange.lowerBound)
        
        return TextAnimationState(
            tracking: tracking,
            opacity: opacity,
            scale: scale,
            rotation: rotation
        )
    }
    
    private func applyState(_ state: TextAnimationState) {
        currentState = state
        
        textLayer.string = textRenderer.attributedString(for: text, fontSize: fontSize, tracking: state.tracking)
        layer.opacity = state.opacity
        layer.transform = CATransform3DMakeScale(state.scale, state.scale, 1.0)
        layer.transform = CATransform3DRotate(layer.transform, state.rotation, 0, 0, 1)
    }
}

// MARK: - AnimationControllerDelegate

extension AnimatedTextView: AnimationControllerDelegate {
    func animationDidUpdate(state: TextAnimationState, progress: AnimationProgress) {
        applyState(state)
    }
    
    func animationDidComplete() {
        // Animation completed - could add completion callbacks here if needed
    }
}
