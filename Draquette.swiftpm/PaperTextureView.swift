import UIKit

class PaperTextureView: UIView {
    
    // MARK: - Constants
    
    private struct Constants {
        // Colors
        static let basePaperColor = UIColor(red: 0.96, green: 0.89, blue: 0.76, alpha: 1)
        static let edgeShadowColor = UIColor(white: 0, alpha: 0.15)
        static let coffeeRingColor = UIColor(red: 0.35, green: 0.2, blue: 0.05, alpha: 0.2)
        static let creaseDarkColor = UIColor(white: 0.3, alpha: 0.1)
        static let creaseLightColor = UIColor(white: 1.0, alpha: 0.04)
        
        // Tears
        static let tearHeight: CGFloat = 4
        static let tearStepMin: CGFloat = 3
        static let tearStepMax: CGFloat = 8
        static let tornEdgeChance: Double = 0.25
        
        // Base Paper Spots
        static let baseSpotRadiusMin: CGFloat = 20
        static let baseSpotRadiusMax: CGFloat = 70
        static let baseSpotAlphaMin: CGFloat = 0.03
        static let baseSpotAlphaMax: CGFloat = 0.07
        static let baseSpotGrayMin: CGFloat = 0.8
        static let baseSpotGrayMax: CGFloat = 0.95
        static let baseSpotCountMin = 60
        static let baseSpotCountMax = 100
        
        // Organic Stains
        static let organicStainAlphaMin: CGFloat = 0.02
        static let organicStainAlphaMax: CGFloat = 0.08
        static let organicStainRadiusMin: CGFloat = 30
        static let organicStainRadiusMax: CGFloat = 80
        static let organicStainPointsMin = 5
        static let organicStainPointsMax = 9
        static let organicStainCountMin = 4
        static let organicStainCountMax = 10
        
        // Coffee ring
        static let coffeeRingChanceOutOf = 8
        
        // Creases
        static let creasesCountMin = 1
        static let creasesCountMax = 4
        
        // Dirt Flecks
        static let dirtFleckClustersMin = 3
        static let dirtFleckClustersMax = 8
        static let dirtFleckCountMin = 10
        static let dirtFleckCountMax = 20
        static let dirtFleckOffsetRange: ClosedRange<CGFloat> = -20...20
        static let dirtFleckSizeMin: CGFloat = 0.5
        static let dirtFleckSizeMax: CGFloat = 2.0
        static let dirtFleckAlphaMin: CGFloat = 0.05
        static let dirtFleckAlphaMax: CGFloat = 0.15
        static let dirtFleckGrayMin: CGFloat = 0.1
        static let dirtFleckGrayMax: CGFloat = 0.3
    }
    
    // MARK: - Instance-scoped Randomization
    
    private let organicStainsCount = Int.random(in: Constants.organicStainCountMin...Constants.organicStainCountMax)
    private let baseSpotCount = Int.random(in: Constants.baseSpotCountMin...Constants.baseSpotCountMax)
    private let creasesCount = Int.random(in: Constants.creasesCountMin...Constants.creasesCountMax)
    private let dirtFleckClusters = Int.random(in: Constants.dirtFleckClustersMin...Constants.dirtFleckClustersMax)
    private let showCoffeeRing = Int.random(in: 0..<Constants.coffeeRingChanceOutOf) == 0
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isOpaque = false
        contentMode = .redraw
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let tornPath = createTornEdgePath(in: rect)
        ctx.addPath(tornPath.cgPath)
        ctx.clip()
        
        drawBasePaperColor(in: ctx, rect: rect)
        drawEdgeShading(in: ctx, rect: rect)
        drawOrganicStains(in: ctx, rect: rect, count: organicStainsCount)
        
        if showCoffeeRing {
            drawCoffeeRing(in: ctx, rect: rect)
        }
        
        drawCreases(in: ctx, rect: rect, count: creasesCount)
        drawDirtFlecks(in: ctx, rect: rect, clusters: dirtFleckClusters)
    }
    
    // MARK: - Drawing Helpers
    
    private func drawBasePaperColor(in ctx: CGContext, rect: CGRect) {
        ctx.setFillColor(Constants.basePaperColor.cgColor)
        ctx.fill(rect)
        
        for _ in 0..<baseSpotCount {
            let radius = CGFloat.random(in: Constants.baseSpotRadiusMin...Constants.baseSpotRadiusMax)
            let center = CGPoint(x: CGFloat.random(in: 0..<rect.width), y: CGFloat.random(in: 0..<rect.height))
            let alpha = CGFloat.random(in: Constants.baseSpotAlphaMin...Constants.baseSpotAlphaMax)
            let gray = CGFloat.random(in: Constants.baseSpotGrayMin...Constants.baseSpotGrayMax)
            
            ctx.setFillColor(UIColor(white: gray, alpha: alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: center.x - radius / 2, y: center.y - radius / 2, width: radius, height: radius))
        }
    }
    
    private func drawEdgeShading(in ctx: CGContext, rect: CGRect) {
        let colors = [UIColor.clear.cgColor, Constants.edgeShadowColor.cgColor]
        let locations: [CGFloat] = [0.7, 1.0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
            ctx.saveGState()
            ctx.setBlendMode(.multiply)
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: min(rect.width, rect.height) / 3,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: max(rect.width, rect.height) / 1.2,
                options: .drawsAfterEndLocation
            )
            ctx.restoreGState()
        }
    }
    
    private func drawOrganicStains(in ctx: CGContext, rect: CGRect, count: Int) {
        for _ in 0..<count {
            let center = CGPoint(x: CGFloat.random(in: 30..<rect.width - 30), y: CGFloat.random(in: 30..<rect.height - 30))
            let baseRadius = CGFloat.random(in: Constants.organicStainRadiusMin...Constants.organicStainRadiusMax)
            let points = Int.random(in: Constants.organicStainPointsMin...Constants.organicStainPointsMax)
            let alpha = CGFloat.random(in: Constants.organicStainAlphaMin...Constants.organicStainAlphaMax)
            
            let path = UIBezierPath()
            var firstPoint: CGPoint?
            
            for i in 0..<points {
                let angle = CGFloat(i) * (2 * .pi / CGFloat(points))
                let radius = baseRadius * CGFloat.random(in: 0.7...1.3)
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius
                let point = CGPoint(x: x, y: y)
                
                if i == 0 {
                    path.move(to: point)
                    firstPoint = point
                } else {
                    path.addLine(to: point)
                }
            }
            
            if let first = firstPoint {
                path.addLine(to: first)
            }
            
            path.close()
            
            let hueOffset = CGFloat.random(in: -0.05...0.05)
            let color = UIColor(red: 0.4 + hueOffset, green: 0.3 + hueOffset, blue: 0.15, alpha: alpha)
            
            ctx.setFillColor(color.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
    }
    
    private func drawCoffeeRing(in ctx: CGContext, rect: CGRect) {
        let ringCenter = CGPoint(x: rect.midX + CGFloat.random(in: -100...100), y: rect.midY + CGFloat.random(in: -40...40))
        let radius = CGFloat.random(in: 30...50)
        let ringPath = UIBezierPath(arcCenter: ringCenter, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        ctx.setStrokeColor(Constants.coffeeRingColor.cgColor)
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        ctx.addPath(ringPath.cgPath)
        ctx.strokePath()
    }
    
    private func drawCreases(in ctx: CGContext, rect: CGRect, count: Int) {
        for _ in 0..<count {
            let start = CGPoint(x: CGFloat.random(in: 0..<rect.width / 2), y: CGFloat.random(in: 0..<rect.height))
            let end = CGPoint(x: start.x + CGFloat.random(in: 100...200), y: start.y + CGFloat.random(in: -20...20))
            
            let path = UIBezierPath()
            path.move(to: start)
            path.addCurve(to: end, controlPoint1: CGPoint(x: start.x + 40, y: start.y - 15), controlPoint2: CGPoint(x: end.x - 40, y: end.y + 15))
            
            ctx.setStrokeColor(Constants.creaseDarkColor.cgColor)
            ctx.setLineWidth(1)
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            
            if Bool.random() {
                ctx.setStrokeColor(Constants.creaseLightColor.cgColor)
                ctx.setLineWidth(0.5)
                ctx.addPath(path.cgPath)
                ctx.strokePath()
            }
        }
    }
    
    private func drawDirtFlecks(in ctx: CGContext, rect: CGRect, clusters: Int) {
        for _ in 0..<clusters {
            let centerX = CGFloat.random(in: 0..<rect.width)
            let centerY = CGFloat.random(in: 0..<rect.height)
            let fleckCount = Int.random(in: Constants.dirtFleckCountMin...Constants.dirtFleckCountMax)
            
            for _ in 0..<fleckCount {
                let offsetX = CGFloat.random(in: Constants.dirtFleckOffsetRange)
                let offsetY = CGFloat.random(in: Constants.dirtFleckOffsetRange)
                let x = centerX + offsetX
                let y = centerY + offsetY
                let size = CGFloat.random(in: Constants.dirtFleckSizeMin...Constants.dirtFleckSizeMax)
                let alpha = CGFloat.random(in: Constants.dirtFleckAlphaMin...Constants.dirtFleckAlphaMax)
                let gray = CGFloat.random(in: Constants.dirtFleckGrayMin...Constants.dirtFleckGrayMax)
                
                ctx.setFillColor(UIColor(white: gray, alpha: alpha).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
            }
        }
    }
    
    private func createTornEdgePath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Top edge
        var x: CGFloat = 0
        while x < rect.width {
            let y = CGFloat.random(in: 0...Constants.tearHeight)
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += CGFloat.random(in: Constants.tearStepMin...Constants.tearStepMax)
        }
        
        // Right edge
        let rightIsTorn = Double.random(in: 0...1) < Constants.tornEdgeChance
        var y: CGFloat = 0
        while y < rect.height {
            let dx: CGFloat = rightIsTorn ? CGFloat.random(in: -Constants.tearHeight...0) : 0
            path.addLine(to: CGPoint(x: rect.width + dx, y: y))
            y += CGFloat.random(in: Constants.tearStepMin...Constants.tearStepMax)
        }
        
        // Bottom edge
        var x2: CGFloat = rect.width
        while x2 > 0 {
            let y = rect.height - CGFloat.random(in: 0...Constants.tearHeight)
            path.addLine(to: CGPoint(x: x2, y: y))
            x2 -= CGFloat.random(in: Constants.tearStepMin...Constants.tearStepMax)
        }
        
        // Left edge
        let leftIsTorn = Double.random(in: 0...1) < Constants.tornEdgeChance
        y = rect.height
        while y > 0 {
            let dx: CGFloat = leftIsTorn ? CGFloat.random(in: 0...Constants.tearHeight) : 0
            path.addLine(to: CGPoint(x: 0 - dx, y: y))
            y -= CGFloat.random(in: Constants.tearStepMin...Constants.tearStepMax)
        }
        
        path.close()
        return path
    }
}
