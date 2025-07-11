import UIKit
import CoreAnimation

// MARK: - Scene Configuration

struct SceneConfiguration {
    let duration: CFTimeInterval
    let backgroundColor: UIColor
    let size: CGSize
    
    static let `default` = SceneConfiguration(
        duration: 10.0,
        backgroundColor: .white,
        size: CGSize(width: 800, height: 600)
    )
}

// MARK: - Keyframe Definition

struct Keyframe {
    let time: CFTimeInterval
    let progress: CGFloat
    let easing: CAMediaTimingFunction?
    
    init(time: CFTimeInterval, progress: CGFloat, easing: CAMediaTimingFunction? = nil) {
        self.time = time
        self.progress = progress
        self.easing = easing
    }
}

// MARK: - Text Element Configuration

struct TextElementConfig {
    let id: String
    let text: String
    let fontSize: CGFloat
    let position: CGPoint
    let configuration: TextAnimationConfiguration
    let keyframes: [Keyframe]
    let startTime: CFTimeInterval
    let duration: CFTimeInterval
    
    init(
        id: String,
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        configuration: TextAnimationConfiguration = .default,
        keyframes: [Keyframe] = [],
        startTime: CFTimeInterval = 0,
        duration: CFTimeInterval = 5.0
    ) {
        self.id = id
        self.text = text
        self.fontSize = fontSize
        self.position = position
        self.configuration = configuration
        self.keyframes = keyframes
        self.startTime = startTime
        self.duration = duration
    }
}

// MARK: - Scene Element

final class SceneElement {
    let config: TextElementConfig
    let textView: AnimatedTextView
    private var currentKeyframeIndex: Int = 0
    
    init(config: TextElementConfig) {
        self.config = config
        self.textView = AnimatedTextView(
            text: config.text,
            fontSize: config.fontSize,
            position: config.position,
            configuration: config.configuration
        )
    }
    
    func update(at time: CFTimeInterval) {
        let elementTime = time - config.startTime
        
        if elementTime < 0 {
            // Element hasn't started yet
            textView.setProgress(0)
            return
        }
        
        if elementTime >= config.duration {
            // Element has completed
            textView.setProgress(1.0)
            return
        }
        
        // Calculate progress based on keyframes
        let progress = calculateProgress(at: elementTime)
        textView.setProgress(progress)
    }
    
    private func calculateProgress(at time: CFTimeInterval) -> CGFloat {
        if config.keyframes.isEmpty {
            // Linear progress if no keyframes
            return CGFloat(time / config.duration)
        }
        
        // Find the appropriate keyframe
        let normalizedTime = CGFloat(time / config.duration)
        
        for (index, keyframe) in config.keyframes.enumerated() {
            if normalizedTime <= keyframe.time / config.duration {
                if index == 0 {
                    return keyframe.progress
                } else {
                    let prevKeyframe = config.keyframes[index - 1]
                    let prevTime = prevKeyframe.time / config.duration
                    let currentTime = keyframe.time / config.duration
                    
                    let segmentProgress = (normalizedTime - prevTime) / (currentTime - prevTime)
                    let easedProgress = keyframe.easing?.evaluate(segmentProgress) ?? segmentProgress
                    
                    return prevKeyframe.progress + easedProgress * (keyframe.progress - prevKeyframe.progress)
                }
            }
        }
        
        return config.keyframes.last?.progress ?? 1.0
    }
}

// MARK: - Motion Graphics Scene

protocol MotionGraphicsSceneDelegate: AnyObject {
    func sceneDidStart()
    func sceneDidUpdate(progress: CGFloat)
    func sceneDidComplete()
}

final class MotionGraphicsScene: NSObject {
    // MARK: Properties
    
    private let configuration: SceneConfiguration
    private weak var delegate: MotionGraphicsSceneDelegate?
    
    private let containerLayer: CALayer
    private var elements: [SceneElement] = []
    
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var isPlaying = false
    
    // MARK: Initialization
    
    init(configuration: SceneConfiguration = .default, delegate: MotionGraphicsSceneDelegate? = nil) {
        self.configuration = configuration
        self.delegate = delegate
        
        self.containerLayer = CALayer()
        self.containerLayer.frame = CGRect(origin: .zero, size: configuration.size)
        self.containerLayer.backgroundColor = configuration.backgroundColor.cgColor
        
        super.init()
    }
    
    // MARK: Public Interface
    
    func addElement(_ config: TextElementConfig) {
        let element = SceneElement(config: config)
        elements.append(element)
        element.textView.addToLayer(containerLayer)
    }
    
    func addToLayer(_ parentLayer: CALayer) {
        parentLayer.addSublayer(containerLayer)
    }
    
    func removeFromParentLayer() {
        containerLayer.removeFromSuperlayer()
    }
    
    func play() {
        guard !isPlaying else { return }
        
        isPlaying = true
        startTime = CACurrentMediaTime()
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateScene))
        displayLink?.add(to: .main, forMode: .default)
        
        delegate?.sceneDidStart()
    }
    
    func pause() {
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func stop() {
        pause()
        resetAllElements()
    }
    
    func setProgress(_ progress: CGFloat) {
        let clampedProgress = max(0, min(1, progress))
        let time = clampedProgress * configuration.duration
        
        updateScene(at: time)
        delegate?.sceneDidUpdate(progress: clampedProgress)
        
        if clampedProgress >= 1.0 {
            delegate?.sceneDidComplete()
        }
    }
    
    // MARK: Private Methods
    
    @objc private func updateScene() {
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - startTime
        
        updateScene(at: elapsed)
        
        let progress = CGFloat(elapsed / configuration.duration)
        delegate?.sceneDidUpdate(progress: progress)
        
        if elapsed >= configuration.duration {
            stop()
            delegate?.sceneDidComplete()
        }
    }
    
    private func updateScene(at time: CFTimeInterval) {
        for element in elements {
            element.update(at: time)
        }
    }
    
    private func resetAllElements() {
        for element in elements {
            element.textView.setProgress(0)
        }
    }
}

// MARK: - Scene Builder

final class MotionGraphicsSceneBuilder {
    private var configuration: SceneConfiguration = .default
    private var elements: [TextElementConfig] = []
    
    func setConfiguration(_ config: SceneConfiguration) -> MotionGraphicsSceneBuilder {
        self.configuration = config
        return self
    }
    
    func addElement(_ config: TextElementConfig) -> MotionGraphicsSceneBuilder {
        elements.append(config)
        return self
    }
    
    func addSimpleElement(
        id: String,
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        startTime: CFTimeInterval = 0,
        duration: CFTimeInterval = 5.0
    ) -> MotionGraphicsSceneBuilder {
        let config = TextElementConfig(
            id: id,
            text: text,
            fontSize: fontSize,
            position: position,
            startTime: startTime,
            duration: duration
        )
        return addElement(config)
    }
    
    func addKeyframedElement(
        id: String,
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        keyframes: [Keyframe],
        startTime: CFTimeInterval = 0,
        duration: CFTimeInterval = 5.0
    ) -> MotionGraphicsSceneBuilder {
        let config = TextElementConfig(
            id: id,
            text: text,
            fontSize: fontSize,
            position: position,
            keyframes: keyframes,
            startTime: startTime,
            duration: duration
        )
        return addElement(config)
    }
    
    func build(delegate: MotionGraphicsSceneDelegate? = nil) -> MotionGraphicsScene {
        let scene = MotionGraphicsScene(configuration: configuration, delegate: delegate)
        
        for elementConfig in elements {
            scene.addElement(elementConfig)
        }
        
        return scene
    }
}

// MARK: - Easing Extensions

extension CAMediaTimingFunction {
    func evaluate(_ time: CGFloat) -> CGFloat {
        var point1 = CGPoint.zero
        var point2 = CGPoint.zero
        getControlPoint(at: 1, values: &point1)
        getControlPoint(at: 2, values: &point2)
        
        // Simple cubic bezier evaluation
        let t = time
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        
        return CGFloat(mt3 * 0 + 3 * mt2 * t * point1.x + 3 * mt * t2 * point2.x + t3 * 1)
    }
} 