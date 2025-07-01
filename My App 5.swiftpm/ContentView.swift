import SwiftUI

struct Metaball: Identifiable {
    let id = UUID()
    var position: CGPoint
    var radius: CGFloat
    var isAnimating: Bool = false
    var velocity: CGFloat = 0
}

struct ContentView: View {
    @State private var metaballs: [Metaball] = []
    @State private var animatedBalls: [Metaball] = []
    @State private var image: Image? = nil
    @State private var baseImage: CGImage? = nil
    
    let renderWidth = 400
    let renderHeight = 600
    let displayWidth: CGFloat = 400
    let displayHeight: CGFloat = 600
    let threshold: Float = 1.0
    
    // Blood red color in RGBA
    let bloodRedRGBA: (r: UInt8, g: UInt8, b: UInt8, a: UInt8) = (153, 0, 0, 255)
    
    @State private var splatterIntensity: Double = 1.0
    @State private var maxRadiusScale: Double = 1.0
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.white
                
                image?
                    .resizable()
                    .frame(width: displayWidth, height: displayHeight)
                    .drawingGroup()
            }
            .frame(width: displayWidth, height: displayHeight)
            .contentShape(Rectangle())
            .onTapGesture { location in
                let scaleX = CGFloat(renderWidth) / displayWidth
                let scaleY = CGFloat(renderHeight) / displayHeight
                let tapX = location.x * scaleX
                let tapY = location.y * scaleY
                let tapPoint = CGPoint(x: tapX, y: tapY)
                
                addSplat(at: tapPoint)
                renderNewBaseLayer()
                startAnimation()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Splatter Intensity")
                    Slider(value: $splatterIntensity, in: 0.1...3.0, step: 0.1)
                }
                
                HStack {
                    Text("Max Radius Scale")
                    Slider(value: $maxRadiusScale, in: 0.5...3.0, step: 0.1)
                }
                
                Button(action: clearCanvas) {
                    Text("Clear")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    func addSplat(at point: CGPoint) {
        func scaledCount(base: ClosedRange<Int>) -> Int {
            let scaled = Double(Int.random(in: base)) * splatterIntensity
            return max(1, Int(scaled.rounded()))
        }
        
        let largeCount = scaledCount(base: 1...3)
        let mediumCount = scaledCount(base: 3...6)
        let tinyCount = scaledCount(base: 10...30)
        
        var newBalls: [Metaball] = []
        
        func randomPoint(near center: CGPoint, maxRadius: CGFloat) -> CGPoint {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let radius = CGFloat.random(in: 0...maxRadius)
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
        
        let scaledLargeRadius = 10 * maxRadiusScale
        let scaledMediumRadius = 30 * maxRadiusScale
        let scaledTinyRadius = 60 * maxRadiusScale
        
        // Large balls are animated drips
        for _ in 0..<largeCount {
            let pos = randomPoint(near: point, maxRadius: scaledLargeRadius)
            let radius = CGFloat.random(in: 12...18)
            newBalls.append(Metaball(position: pos, radius: radius, isAnimating: true, velocity: 0))
        }
        
        // Medium and tiny balls are static
        for _ in 0..<mediumCount {
            let pos = randomPoint(near: point, maxRadius: scaledMediumRadius)
            let radius = CGFloat.random(in: 7...12)
            newBalls.append(Metaball(position: pos, radius: radius))
        }
        
        for _ in 0..<tinyCount {
            let pos = randomPoint(near: point, maxRadius: scaledTinyRadius)
            let radius = CGFloat.random(in: 2...5)
            newBalls.append(Metaball(position: pos, radius: radius))
        }
        
        metaballs.append(contentsOf: newBalls)
    }
    
    func renderNewBaseLayer() {
        // Render all static metaballs and animated balls as base, except animated drips will be removed during animation
        let staticBalls = metaballs.filter { !$0.isAnimating }
        renderMetaballs(balls: staticBalls, blendMode: .multiply, updateBase: true)
    }
    
    func startAnimation() {
        // Extract animated balls from metaballs to animatedBalls list and remove from base metaballs
        animatedBalls = metaballs.filter { $0.isAnimating }
        metaballs.removeAll(where: { $0.isAnimating })
        
        let gravity: CGFloat = 0.3
        let animationInterval = 1.0 / 30.0
        
        Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { timer in
            var updated: [Metaball] = []
            
            for var ball in animatedBalls {
                ball.velocity += gravity
                ball.position.y += ball.velocity
                
                // Leave a trail metaball, smaller radius, non-animating
                let trailRadius = max(1, ball.radius * 0.2)
                metaballs.append(Metaball(position: ball.position, radius: trailRadius))
                
                if ball.position.y + ball.radius >= CGFloat(renderHeight) {
                    // Drip landed — create a small splatter puddle near bottom
                    let puddleSplatter = generateSplat(at: CGPoint(x: ball.position.x, y: CGFloat(renderHeight - 5)))
                    metaballs.append(contentsOf: puddleSplatter)
                    // This drip is done, don't add to updated
                } else {
                    updated.append(ball)
                }
            }
            
            animatedBalls = updated
            
            // Render base layer (static metaballs) with multiply blend mode
            renderMetaballs(balls: metaballs, blendMode: .multiply, updateBase: true)
            // Render animated drips + trails normally (no multiply)
            renderMetaballs(balls: animatedBalls + metaballs.filter { $0.radius <= 2 }, blendMode: .normal, updateBase: false)
            
            if animatedBalls.isEmpty {
                timer.invalidate()
            }
        }
    }
    
    func generateSplat(at point: CGPoint) -> [Metaball] {
        // Small splatter like a puddle
        var splat: [Metaball] = []
        let count = Int.random(in: 10...20)
        
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 0...10)
            let pos = CGPoint(
                x: point.x + cos(angle) * dist,
                y: point.y + sin(angle) * dist
            )
            let radius = CGFloat.random(in: 3...7)
            splat.append(Metaball(position: pos, radius: radius))
        }
        return splat
    }
    
    func renderMetaballs(balls: [Metaball], blendMode: CGBlendMode, updateBase: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            let bytesPerPixel = 4
            let totalBytes = renderWidth * renderHeight * bytesPerPixel
            var pixelData = [UInt8](repeating: 255, count: totalBytes) // White background
            
            let ballsData = balls.map { ($0.position, Float($0.radius * $0.radius)) }
            let maxRadius = balls.map { $0.radius }.max() ?? 20
            let cutoffDistSq = Float(maxRadius * maxRadius * 4)
            
            DispatchQueue.concurrentPerform(iterations: renderHeight) { y in
                for x in 0..<renderWidth {
                    var fieldValue: Float = 0
                    let px = Float(x)
                    let py = Float(y)
                    
                    for (pos, rSq) in ballsData {
                        let dx = px - Float(pos.x)
                        let dy = py - Float(pos.y)
                        let distSq = dx * dx + dy * dy
                        if distSq > cutoffDistSq { continue }
                        if distSq > 0 {
                            let influence = rSq / distSq
                            fieldValue += influence
                            if fieldValue >= threshold { break }
                        }
                    }
                    
                    let offset = (y * renderWidth + x) * bytesPerPixel
                    if fieldValue >= threshold {
                        // Blood red
                        pixelData[offset + 0] = bloodRedRGBA.r
                        pixelData[offset + 1] = bloodRedRGBA.g
                        pixelData[offset + 2] = bloodRedRGBA.b
                        pixelData[offset + 3] = bloodRedRGBA.a
                    }
                }
            }
            
            guard let newImage = makeCGImage(from: pixelData, width: renderWidth, height: renderHeight) else { return }
            
            let finalImage = compositeImages(
                base: updateBase ? baseImage : nil,
                top: newImage,
                blendMode: blendMode
            )
            
            DispatchQueue.main.async {
                if updateBase {
                    self.baseImage = finalImage
                }
                self.image = Image(decorative: finalImage!, scale: 1.0)
            }
        }
    }
    
    func compositeImages(base: CGImage?, top: CGImage, blendMode: CGBlendMode) -> CGImage? {
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
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        
        if let base = base {
            context.setBlendMode(.normal)
            context.draw(base, in: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        }
        
        context.setBlendMode(blendMode)
        context.draw(top, in: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight))
        
        return context.makeImage()
    }
    
    func clearCanvas() {
        metaballs.removeAll()
        animatedBalls.removeAll()
        baseImage = nil
        image = nil
    }
    
    func makeCGImage(from data: [UInt8], width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let provider = CGDataProvider(data: NSData(bytes: data, length: data.count)) else {
            return nil
        }
        
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
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
