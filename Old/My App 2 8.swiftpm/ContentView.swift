import SwiftUI
import CoreGraphics

struct Metaball {
    var position: CGPoint
    var radius: CGFloat
}

struct ContentView: View {
    @State private var splatQueue: [[Metaball]] = []
    @State private var baseImage: CGImage? = nil
    @State private var image: Image? = nil
    @State private var splatLevel: Int = 0
    
    @State private var renderWidth: Int = 400
    @State private var renderHeight: Int = 600
    
    let threshold: Float = 1.0
    let bloodRedRGBA: (r: UInt8, g: UInt8, b: UInt8, a: UInt8) = (153, 0, 0, 255)
    let pipelineSize = 8
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                image?
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                // Convert tap location to render coords
                let tapX = location.x
                let tapY = location.y
                
                addSplat(at: CGPoint(x: tapX, y: tapY))
            }
            .onChange(of: geo.size) { newSize in
                // Update render size and clear canvas to resize correctly
                let newWidth = Int(newSize.width)
                let newHeight = Int(newSize.height)
                
                if newWidth != renderWidth || newHeight != renderHeight {
                    renderWidth = newWidth
                    renderHeight = newHeight
                    clearCanvas()
                }
            }
            .onAppear {
                renderWidth = Int(geo.size.width)
                renderHeight = Int(geo.size.height)
                splatQueue.removeAll()
                baseImage = nil
                image = nil
                splatLevel = 0
                
                for _ in 0..<pipelineSize {
                    generateSplatAsync(level: splatLevel)
                }
            }
        }
        .edgesIgnoringSafeArea(.all) // Make sure it covers full screen
    }
    
    func generateSplatAsync(level: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let metaballs = generateMetaballs(center: CGPoint.zero, level: level)
            DispatchQueue.main.async {
                splatQueue.append(metaballs)
            }
        }
    }
    
    func generateMetaballs(center: CGPoint, level: Int) -> [Metaball] {
        var balls = [Metaball]()
        
        // Progressive increase in metaball counts
        let baseLargeCount = Int.random(in: 1...3)
        let baseMediumCount = Int.random(in: 3...6)
        let baseTinyCount = Int.random(in: 10...30)
        
        let largeCount = baseLargeCount + level * 2
        let mediumCount = baseMediumCount + level * 4
        let tinyCount = baseTinyCount + level * 8
        
        func randomPoint(near center: CGPoint, maxRadius: CGFloat) -> CGPoint {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let radius = CGFloat.random(in: 0...maxRadius)
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
        
        let baseMaxRadiusScale: CGFloat = 1.0
        let maxRadiusScale = baseMaxRadiusScale * CGFloat(1 + Double(level) * 0.5)
        
        let scaledLargeRadius = 20 * maxRadiusScale
        let scaledMediumRadius = 60 * maxRadiusScale
        let scaledTinyRadius = 120 * maxRadiusScale
        
        for _ in 0..<largeCount {
            let pos = randomPoint(near: center, maxRadius: scaledLargeRadius)
            let radius = CGFloat.random(in: 12...18) * maxRadiusScale
            balls.append(Metaball(position: pos, radius: radius))
        }
        
        for _ in 0..<mediumCount {
            let pos = randomPoint(near: center, maxRadius: scaledMediumRadius)
            let radius = CGFloat.random(in: 7...12) * maxRadiusScale
            balls.append(Metaball(position: pos, radius: radius))
        }
        
        for _ in 0..<tinyCount {
            let pos = randomPoint(near: center, maxRadius: scaledTinyRadius)
            let radius = CGFloat.random(in: 2...5) * maxRadiusScale
            balls.append(Metaball(position: pos, radius: radius))
        }
        
        return balls
    }
    
    func addSplat(at tapLocation: CGPoint) {
        guard !splatQueue.isEmpty else { return }
        
        let metaballsToDraw = splatQueue.removeFirst()
        generateSplatAsync(level: splatLevel + pipelineSize)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let bytesPerPixel = 4
            let totalBytes = renderWidth * renderHeight * bytesPerPixel
            var pixelData = [UInt8](repeating: 0, count: totalBytes)
            
            // Shift metaballs by tapLocation
            let shiftedBalls = metaballsToDraw.map { ball -> (positionX: Float, positionY: Float, radiusSq: Float) in
                let x = Float(ball.position.x + tapLocation.x)
                let y = Float(ball.position.y + tapLocation.y)
                return (positionX: x, positionY: y, radiusSq: Float(ball.radius * ball.radius))
            }
            
            let maxRadius = metaballsToDraw.map { $0.radius }.max() ?? 20
            let cutoffDistSq = Float(maxRadius * maxRadius * 4)
            
            for y in 0..<renderHeight {
                let py = Float(y)
                let rowOffset = y * renderWidth * bytesPerPixel
                for x in 0..<renderWidth {
                    let px = Float(x)
                    
                    var fieldValue: Float = 0
                    for ball in shiftedBalls {
                        let dx = px - ball.positionX
                        let dy = py - ball.positionY
                        let distSq = dx*dx + dy*dy
                        if distSq > cutoffDistSq { continue }
                        if distSq > 0 {
                            let influence = ball.radiusSq / distSq
                            fieldValue += influence
                            if fieldValue >= threshold { break }
                        }
                    }
                    
                    if fieldValue >= threshold {
                        let offset = rowOffset + x * bytesPerPixel
                        pixelData[offset + 0] = bloodRedRGBA.r
                        pixelData[offset + 1] = bloodRedRGBA.g
                        pixelData[offset + 2] = bloodRedRGBA.b
                        pixelData[offset + 3] = bloodRedRGBA.a
                    }
                }
            }
            
            guard let newSplatImage = makeCGImage(from: pixelData, width: renderWidth, height: renderHeight) else {
                return
            }
            
            let combinedImage = compositeImages(base: baseImage, top: newSplatImage)
            
            DispatchQueue.main.async {
                baseImage = combinedImage
                image = Image(decorative: combinedImage ?? newSplatImage, scale: 1.0)
                splatLevel += 1
            }
        }
    }
    
    func compositeImages(base: CGImage?, top: CGImage) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: renderWidth,
            height: renderHeight,
            bitsPerComponent: 8,
            bytesPerRow: renderWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        if let base = base {
            context.draw(base, in: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        } else {
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        }
        
        context.setBlendMode(.normal)
        context.draw(top, in: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        
        return context.makeImage()
    }
    
    func clearCanvas() {
        baseImage = nil
        image = nil
        splatQueue.removeAll()
        splatLevel = 0
        for _ in 0..<pipelineSize {
            generateSplatAsync(level: splatLevel)
        }
    }
    
    func makeCGImage(from data: [UInt8], width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let provider = CGDataProvider(data: NSData(bytes: data, length: data.count)) else { return nil }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}

