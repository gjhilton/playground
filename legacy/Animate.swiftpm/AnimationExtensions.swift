import UIKit

// MARK: - Extended Animation Configurations

extension TextAnimationConfiguration {
    static let fast = TextAnimationConfiguration(
        trackingRange: 5...15,
        opacityRange: 0...1,
        scaleRange: 1...1,
        rotationRange: 0...0
    )
    
    static let slow = TextAnimationConfiguration(
        trackingRange: 15...30,
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
    
    static let bounce = TextAnimationConfiguration(
        trackingRange: 10...20,
        opacityRange: 0...1,
        scaleRange: 0.5...1.1,
        rotationRange: 0...0
    )
    
    static let spin = TextAnimationConfiguration(
        trackingRange: 10...20,
        opacityRange: 0...1,
        scaleRange: 1...1,
        rotationRange: 0...2 * .pi
    )
    
    static func custom(
        trackingRange: ClosedRange<CGFloat>,
        opacityRange: ClosedRange<Float> = 0...1,
        scaleRange: ClosedRange<CGFloat> = 1...1,
        rotationRange: ClosedRange<CGFloat> = 0...0
    ) -> TextAnimationConfiguration {
        TextAnimationConfiguration(
            trackingRange: trackingRange,
            opacityRange: opacityRange,
            scaleRange: scaleRange,
            rotationRange: rotationRange
        )
    }
}

// MARK: - Custom Text Renderers

struct BoldTextRenderer: TextRenderer {
    func attributedString(for text: String, fontSize: CGFloat, tracking: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .kern: tracking,
            .foregroundColor: UIColor.black.cgColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func calculateWidth(for text: String, fontSize: CGFloat, tracking: CGFloat) -> CGFloat {
        let attrStr = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .kern: tracking
            ]
        )
        
        let line = CTLineCreateWithAttributedString(attrStr as CFAttributedString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        return ceil(lineBounds.width + abs(lineBounds.origin.x)) + 20
    }
}

struct ColoredTextRenderer: TextRenderer {
    let color: UIColor
    
    init(color: UIColor = .systemBlue) {
        self.color = color
    }
    
    func attributedString(for text: String, fontSize: CGFloat, tracking: CGFloat) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .kern: tracking,
            .foregroundColor: color.cgColor
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

// MARK: - Motion Graphics Scene Presets

extension MotionGraphicsSceneBuilder {
    static func createMovieIntro() -> MotionGraphicsSceneBuilder {
        MotionGraphicsSceneBuilder()
            .setConfiguration(SceneConfiguration(
                duration: 15.0,
                backgroundColor: .black,
                size: CGSize(width: 800, height: 600)
            ))
            .addKeyframedElement(
                id: "studio",
                text: "STUDIO NAME",
                fontSize: 24,
                position: CGPoint(x: 400, y: 150),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 2, progress: 0.5, easing: CAMediaTimingFunction(name: .easeInEaseOut)),
                    Keyframe(time: 4, progress: 1.0)
                ],
                startTime: 0,
                duration: 4.0
            )
            .addKeyframedElement(
                id: "title",
                text: "EPIC MOVIE TITLE",
                fontSize: 36,
                position: CGPoint(x: 400, y: 250),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 1, progress: 0.3),
                    Keyframe(time: 3, progress: 0.8, easing: CAMediaTimingFunction(name: .easeOut)),
                    Keyframe(time: 5, progress: 1.0)
                ],
                startTime: 3.0,
                duration: 5.0
            )
            .addKeyframedElement(
                id: "subtitle",
                text: "Coming Soon",
                fontSize: 18,
                position: CGPoint(x: 400, y: 320),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 2, progress: 1.0, easing: CAMediaTimingFunction(name: .easeIn))
                ],
                startTime: 8.0,
                duration: 2.0
            )
            .addKeyframedElement(
                id: "date",
                text: "2024",
                fontSize: 16,
                position: CGPoint(x: 400, y: 380),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 1, progress: 1.0)
                ],
                startTime: 10.0,
                duration: 1.0
            )
    }
    
    static func createProductLaunch() -> MotionGraphicsSceneBuilder {
        MotionGraphicsSceneBuilder()
            .setConfiguration(SceneConfiguration(
                duration: 12.0,
                backgroundColor: .white,
                size: CGSize(width: 800, height: 600)
            ))
            .addKeyframedElement(
                id: "brand",
                text: "BRAND NAME",
                fontSize: 28,
                position: CGPoint(x: 400, y: 180),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 1.5, progress: 0.7, easing: CAMediaTimingFunction(name: .easeOut)),
                    Keyframe(time: 3, progress: 1.0)
                ],
                startTime: 0,
                duration: 3.0
            )
            .addKeyframedElement(
                id: "product",
                text: "NEW PRODUCT",
                fontSize: 32,
                position: CGPoint(x: 400, y: 250),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 2, progress: 0.5),
                    Keyframe(time: 4, progress: 1.0)
                ],
                startTime: 2.0,
                duration: 4.0
            )
            .addKeyframedElement(
                id: "tagline",
                text: "Revolutionary Design",
                fontSize: 18,
                position: CGPoint(x: 400, y: 320),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 1, progress: 1.0)
                ],
                startTime: 6.0,
                duration: 1.0
            )
            .addKeyframedElement(
                id: "cta",
                text: "Learn More",
                fontSize: 16,
                position: CGPoint(x: 400, y: 380),
                keyframes: [
                    Keyframe(time: 0, progress: 0),
                    Keyframe(time: 0.5, progress: 1.0)
                ],
                startTime: 8.0,
                duration: 0.5
            )
    }
    
    static func createMinimalistIntro() -> MotionGraphicsSceneBuilder {
        MotionGraphicsSceneBuilder()
            .setConfiguration(SceneConfiguration(
                duration: 8.0,
                backgroundColor: .white,
                size: CGSize(width: 800, height: 600)
            ))
            .addSimpleElement(
                id: "title",
                text: "MINIMAL",
                fontSize: 40,
                position: CGPoint(x: 400, y: 250),
                startTime: 0,
                duration: 4.0
            )
            .addSimpleElement(
                id: "subtitle",
                text: "design",
                fontSize: 24,
                position: CGPoint(x: 400, y: 320),
                startTime: 2.0,
                duration: 4.0
            )
    }
}

// MARK: - Animation Factory

struct AnimatedTextViewFactory {
    static func createTitleView(
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        configuration: TextAnimationConfiguration = .default,
        renderer: TextRenderer = DefaultTextRenderer()
    ) -> AnimatedTextView {
        AnimatedTextView(
            text: text,
            fontSize: fontSize,
            position: position,
            configuration: configuration,
            textRenderer: renderer
        )
    }
    
    static func createBoldTitleView(
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        configuration: TextAnimationConfiguration = .default
    ) -> AnimatedTextView {
        createTitleView(
            text: text,
            fontSize: fontSize,
            position: position,
            configuration: configuration,
            renderer: BoldTextRenderer()
        )
    }
    
    static func createColoredTitleView(
        text: String,
        fontSize: CGFloat,
        position: CGPoint,
        color: UIColor,
        configuration: TextAnimationConfiguration = .default
    ) -> AnimatedTextView {
        createTitleView(
            text: text,
            fontSize: fontSize,
            position: position,
            configuration: configuration,
            renderer: ColoredTextRenderer(color: color)
        )
    }
    
    static func createDramaticView(
        text: String,
        fontSize: CGFloat,
        position: CGPoint
    ) -> AnimatedTextView {
        createTitleView(
            text: text,
            fontSize: fontSize,
            position: position,
            configuration: .dramatic
        )
    }
    
    static func createBounceView(
        text: String,
        fontSize: CGFloat,
        position: CGPoint
    ) -> AnimatedTextView {
        createTitleView(
            text: text,
            fontSize: fontSize,
            position: position,
            configuration: .bounce
        )
    }
}

// MARK: - Keyframe Presets

extension Keyframe {
    static func easeIn(at time: CFTimeInterval, progress: CGFloat) -> Keyframe {
        Keyframe(
            time: time,
            progress: progress,
            easing: CAMediaTimingFunction(name: .easeIn)
        )
    }
    
    static func easeOut(at time: CFTimeInterval, progress: CGFloat) -> Keyframe {
        Keyframe(
            time: time,
            progress: progress,
            easing: CAMediaTimingFunction(name: .easeOut)
        )
    }
    
    static func easeInOut(at time: CFTimeInterval, progress: CGFloat) -> Keyframe {
        Keyframe(
            time: time,
            progress: progress,
            easing: CAMediaTimingFunction(name: .easeInEaseOut)
        )
    }
    
    static func linear(at time: CFTimeInterval, progress: CGFloat) -> Keyframe {
        Keyframe(time: time, progress: progress)
    }
} 