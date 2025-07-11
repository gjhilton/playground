import UIKit

struct TornPaperTextureGenerator {
    static func createTornPaperPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let margin: CGFloat = 15
        let n = Style.tornEdgeVertices
        let amplitudeY: CGFloat = Style.tornEdgeVerticalJitter
        let amplitudeX: CGFloat = Style.tornEdgeHorizontalJitter
        // Top edge
        var topPoints: [CGPoint] = []
        var lastX: CGFloat = margin
        for i in 0..<n {
            let remaining = n - i
            let maxStep = (width - 2 * margin - (lastX - margin)) / CGFloat(remaining)
            let step = CGFloat.random(in: maxStep * 0.7...maxStep * 1.3)
            let x = min(width - margin, lastX + step + CGFloat.random(in: -amplitudeX...amplitudeX))
            let y = margin + CGFloat.random(in: -amplitudeY...amplitudeY)
            topPoints.append(CGPoint(x: x, y: y))
            lastX = x
        }
        // Bottom edge
        var bottomPoints: [CGPoint] = []
        lastX = width - margin
        for i in 0..<n {
            let remaining = n - i
            let maxStep = (width - 2 * margin - (width - margin - lastX)) / CGFloat(remaining)
            let step = CGFloat.random(in: maxStep * 0.7...maxStep * 1.3)
            let x = max(margin, lastX - step + CGFloat.random(in: -amplitudeX...amplitudeX))
            let y = height - margin + CGFloat.random(in: -amplitudeY...amplitudeY)
            bottomPoints.append(CGPoint(x: x, y: y))
            lastX = x
        }
        // Start at top-left
        path.move(to: topPoints[0])
        // Draw top edge
        for pt in topPoints.dropFirst() {
            path.addLine(to: pt)
        }
        // Draw right edge (connect last top to first bottom)
        path.addLine(to: bottomPoints[0])
        // Draw bottom edge
        for pt in bottomPoints.dropFirst() {
            path.addLine(to: pt)
        }
        // Draw left edge (connect last bottom to first top)
        path.addLine(to: topPoints[0])
        path.close()
        return path
    }
    static func createTornTexturePath(in rect: CGRect) -> UIBezierPath {
        // No extra texture needed with this detailed edge
        return UIBezierPath()
    }
}

class TornPaperButtonView: UIView {
    private var tornPaperLayer: CAShapeLayer!
    private var shadowLayer: CAShapeLayer!
    private var textLayer: CATextLayer!
    private var tornTextureLayer: CAShapeLayer!
    
    private let title: String
    private let font: UIFont
    private let isMain: Bool
    
    init(title: String, font: UIFont, isMain: Bool) {
        self.title = title
        self.font = font
        self.isMain = isMain
        super.init(frame: .zero)
        setupTornPaperButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTornPaperButton() {
        backgroundColor = .clear
        layer.masksToBounds = false
        // Create shadow layer
        shadowLayer = CAShapeLayer()
        shadowLayer.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOffset = Style.menuButtonShadow
        shadowLayer.shadowOpacity = Style.menuButtonShadowOpacity
        shadowLayer.shadowRadius = Style.menuButtonShadowRadius
        layer.addSublayer(shadowLayer)
        // Create torn paper layer
        tornPaperLayer = CAShapeLayer()
        tornPaperLayer.fillColor = Style.backgroundColor.cgColor
        tornPaperLayer.strokeColor = Style.textColor.withAlphaComponent(0.2).cgColor
        tornPaperLayer.lineWidth = 1.0
        layer.addSublayer(tornPaperLayer)
        // Create torn texture layer for ragged edges
        tornTextureLayer = CAShapeLayer()
        tornTextureLayer.fillColor = Style.textColor.withAlphaComponent(0.1).cgColor
        layer.addSublayer(tornTextureLayer)
        // Create text layer
        textLayer = CATextLayer()
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = Style.textColor.cgColor
        textLayer.fontSize = font.pointSize
        textLayer.font = font
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.string = title
        layer.addSublayer(textLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTornPaperPath()
        updateTextLayer()
    }
    
    private func updateTornPaperPath() {
        let bounds = self.bounds
        let path = TornPaperTextureGenerator.createTornPaperPath(in: bounds)
        let texturePath = TornPaperTextureGenerator.createTornTexturePath(in: bounds)
        // Update shadow layer
        shadowLayer.path = path.cgPath
        shadowLayer.frame = bounds
        // Update torn paper layer
        tornPaperLayer.path = path.cgPath
        tornPaperLayer.frame = bounds
        // Update texture layer
        tornTextureLayer.path = texturePath.cgPath
        tornTextureLayer.frame = bounds
    }
    
    private func updateTextLayer() {
        let bounds = self.bounds
        textLayer.frame = CGRect(x: 20, y: (bounds.height - 30) / 2, width: bounds.width - 40, height: 30)
        textLayer.fontSize = font.pointSize
        textLayer.font = font
        textLayer.string = title
    }
} 