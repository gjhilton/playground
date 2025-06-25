import SwiftUI

// MARK: - Config with persistence via AppStorage

class SpatterSettings: ObservableObject {
    @AppStorage("scaleMultiplier") var scaleMultiplier: Double = 4.0
    @AppStorage("dropletCountMultiplier") var dropletCountMultiplier: Double = 6.0
    @AppStorage("maxRadius") var maxRadius: Double = 320.0
    @AppStorage("tailLengthMultiplier") var tailLengthMultiplier: Double = 10.0
    
    var baseSize: CGFloat { CGFloat(2.0 * scaleMultiplier) }
    var maxDroplets: Int { Int(120 * scaleMultiplier * dropletCountMultiplier) }
    var minDroplets: Int { Int(20 * scaleMultiplier * dropletCountMultiplier / 2) }
    var maxRadiusCGFloat: CGFloat { CGFloat(maxRadius) }
    var minRadius: CGFloat { 5 * baseSize / 2 }
    var tailLengthMultiplierCGFloat: CGFloat { CGFloat(tailLengthMultiplier) }
    
    let swipeThreshold: CGFloat = 10
}

// MARK: - Models

struct Spatter: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let droplets: [Droplet]
}

struct Droplet {
    let offset: CGSize
    let size: CGSize
    let opacity: Double
    let color: Color
    let rotation: Angle
    let hasTail: Bool
    let tailLength: CGFloat
    let tailAngle: Angle
    let satellites: [SatelliteDrop]
}

struct SatelliteDrop {
    let offset: CGSize
    let size: CGFloat
    let opacity: Double
    let color: Color
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var settings = SpatterSettings()
    @State private var spatters: [Spatter] = []
    @State private var dragStart: CGPoint?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white.ignoresSafeArea()
                
                Canvas { context, size in
                    for spatter in spatters {
                        draw(spatter: spatter, in: context)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in dragStart = value.startLocation }
                        .onEnded { value in
                            guard let start = dragStart else { return }
                            let end = value.location
                            let delta = hypot(end.x - start.x, end.y - start.y)
                            let velocity = CGVector(dx: end.x - start.x, dy: end.y - start.y)
                            
                            let newSpatter: Spatter
                            if delta < settings.swipeThreshold {
                                newSpatter = generateTapSpatter(at: end)
                            } else {
                                newSpatter = generateSwipeSpatter(at: end, with: velocity)
                            }
                            
                            spatters.append(newSpatter)
                            dragStart = nil
                        }
                )
            }
            
            // MARK: - Controls
            
            VStack(spacing: 16) {
                ParameterSlider(title: "Scale (Size)", value: $settings.scaleMultiplier, range: 1...8, step: 0.1)
                ParameterSlider(title: "Droplet Count Multiplier", value: $settings.dropletCountMultiplier, range: 1...10, step: 0.1)
                ParameterSlider(title: "Max Spread Radius", value: $settings.maxRadius, range: 100...600, step: 5)
                ParameterSlider(title: "Tail Length Multiplier", value: $settings.tailLengthMultiplier, range: 1...20, step: 0.5)
                
                Button("Clear Spatters") {
                    spatters.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding()
            .background(Color(white: 0.95))
        }
        .animation(.easeInOut, value: settings.scaleMultiplier)
        .animation(.easeInOut, value: settings.dropletCountMultiplier)
        .animation(.easeInOut, value: settings.maxRadius)
        .animation(.easeInOut, value: settings.tailLengthMultiplier)
    }
    
    // MARK: - Spatter Generators
    
    func generateTapSpatter(at point: CGPoint) -> Spatter {
        var droplets: [Droplet] = []
        
        let impactSize = 80 * CGFloat(settings.scaleMultiplier)
        let impactColor = Color(red: 0.35, green: 0.0, blue: 0.0, opacity: 1.0)
        droplets.append(
            Droplet(
                offset: .zero,
                size: CGSize(width: impactSize, height: impactSize),
                opacity: 1.0,
                color: impactColor,
                rotation: .degrees(0),
                hasTail: false,
                tailLength: 0,
                tailAngle: .degrees(0),
                satellites: []
            )
        )
        
        let count = settings.minDroplets
        for _ in 0..<count {
            let angle = Double.random(in: 0..<(2 * Double.pi))
            let distance = CGFloat.random(in: 0...(impactSize * 0.6))
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            
            let baseRadius = CGFloat.random(in: 8...20) * settings.baseSize
            let stretch = CGFloat.random(in: 1.0...1.8)
            let size = CGSize(width: baseRadius * stretch, height: baseRadius)
            
            let rotation = Angle(degrees: Double.random(in: 0...360))
            let opacity = Double.random(in: 0.6...1.0)
            
            let hue = Double.random(in: 0.95...1.0)
            let saturation = Double.random(in: 0.9...1.0)
            let brightness = Double.random(in: 0.3...0.7)
            let color = Color(hue: hue, saturation: saturation, brightness: brightness)
            
            droplets.append(
                Droplet(
                    offset: CGSize(width: dx, height: dy),
                    size: size,
                    opacity: opacity,
                    color: color,
                    rotation: rotation,
                    hasTail: false,
                    tailLength: 0,
                    tailAngle: .degrees(0),
                    satellites: []
                )
            )
        }
        
        return Spatter(origin: point, droplets: droplets)
    }
    
    func generateSwipeSpatter(at point: CGPoint, with velocity: CGVector) -> Spatter {
        var droplets: [Droplet] = []
        
        let baseAngle = atan2(velocity.dy, velocity.dx)
        let strength = hypot(velocity.dx, velocity.dy)
        let dropletCount = settings.maxDroplets
        
        let impactSize = 40 * CGFloat(settings.scaleMultiplier)
        let impactColor = Color(red: 0.35, green: 0.0, blue: 0.0, opacity: 0.9)
        droplets.append(
            Droplet(
                offset: .zero,
                size: CGSize(width: impactSize, height: impactSize),
                opacity: 1.0,
                color: impactColor,
                rotation: .degrees(0),
                hasTail: false,
                tailLength: 0,
                tailAngle: .degrees(0),
                satellites: []
            )
        )
        
        for _ in 0..<dropletCount {
            let angleOffset = Double.random(in: -45...45)
            let angle = baseAngle + angleOffset * .pi / 180
            let distance = CGFloat.random(in: settings.minRadius...settings.maxRadiusCGFloat)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            
            let baseRadius = CGFloat.random(in: 4...16) * settings.baseSize
            let stretch = CGFloat.random(in: 1.5...4.5)
            let size = CGSize(width: baseRadius * stretch, height: baseRadius)
            
            let rotation = Angle(radians: angle)
            let opacity = Double.random(in: 0.3...0.85)
            
            let hue = Double.random(in: 0.95...1.0)
            let saturation = Double.random(in: 0.8...1.0)
            let brightness = Double.random(in: 0.2...0.6)
            let color = Color(hue: hue, saturation: saturation, brightness: brightness)
            
            let hasTail = Bool.random(probability: 0.5)
            let tailLength = hasTail ? baseRadius * settings.tailLengthMultiplierCGFloat * CGFloat.random(in: 0.6...1.2) : 0
            let tailAngle = rotation
            
            let satelliteCount = Int.random(in: 0...3)
            var satellites: [SatelliteDrop] = []
            for _ in 0..<satelliteCount {
                let satAngle = Double.random(in: 0..<(2 * Double.pi))
                let satDist = baseRadius * CGFloat.random(in: 0.7...1.3)
                let satOffset = CGSize(
                    width: cos(satAngle) * satDist,
                    height: sin(satAngle) * satDist
                )
                let satSize = CGFloat.random(in: 2...6)
                let satOpacity = opacity * Double.random(in: 0.4...0.9)
                let satColor = color.opacity(satOpacity)
                
                satellites.append(SatelliteDrop(
                    offset: satOffset,
                    size: satSize,
                    opacity: satOpacity,
                    color: satColor
                ))
            }
            
            droplets.append(
                Droplet(
                    offset: CGSize(width: dx, height: dy),
                    size: size,
                    opacity: opacity,
                    color: color,
                    rotation: rotation,
                    hasTail: hasTail,
                    tailLength: tailLength,
                    tailAngle: tailAngle,
                    satellites: satellites
                )
            )
        }
        
        return Spatter(origin: point, droplets: droplets)
    }
    
    // MARK: - Drawing Helpers
    
    func draw(spatter: Spatter, in context: GraphicsContext) {
        for droplet in spatter.droplets {
            let center = CGPoint(
                x: spatter.origin.x + droplet.offset.width,
                y: spatter.origin.y + droplet.offset.height
            )
            
            let mainPath = makeSmoothIrregularBlob(center: center, size: droplet.size, rotation: droplet.rotation)
            context.fill(mainPath, with: .color(droplet.color.opacity(droplet.opacity)))
            
            if droplet.hasTail {
                let tailPath = makeTailPath(
                    from: center,
                    length: droplet.tailLength,
                    width: droplet.size.height * 0.6,
                    angle: droplet.tailAngle
                )
                context.fill(tailPath, with: .color(droplet.color.opacity(droplet.opacity * 0.4)))
            }
            
            for satellite in droplet.satellites {
                let satCenter = CGPoint(
                    x: center.x + satellite.offset.width,
                    y: center.y + satellite.offset.height
                )
                let satPath = makeSmoothIrregularBlob(
                    center: satCenter,
                    size: CGSize(width: satellite.size, height: satellite.size),
                    rotation: .degrees(Double.random(in: 0...360))
                )
                context.fill(satPath, with: .color(satellite.color))
            }
        }
    }
    
    func makeSmoothIrregularBlob(center: CGPoint, size: CGSize, rotation: Angle) -> Path {
        let pointsCount = 8
        let baseRadiusX = size.width / 2
        let baseRadiusY = size.height / 2
        let irregularity = 0.3
        
        var points: [CGPoint] = []
        let angleStep = 2 * Double.pi / Double(pointsCount)
        
        for i in 0..<pointsCount {
            let angle = Double(i) * angleStep + rotation.radians
            let radiusX = baseRadiusX * CGFloat(1 + Double.random(in: -irregularity...irregularity))
            let radiusY = baseRadiusY * CGFloat(1 + Double.random(in: -irregularity...irregularity))
            
            let x = center.x + cos(angle) * radiusX
            let y = center.y + sin(angle) * radiusY
            points.append(CGPoint(x: x, y: y))
        }
        
        return Path { path in
            guard points.count > 3 else {
                path.addLines(points)
                path.closeSubpath()
                return
            }
            
            func controlPoints(for p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) -> (CGPoint, CGPoint) {
                let smoothing: CGFloat = 0.3
                let d01 = hypot(p1.x - p0.x, p1.y - p0.y)
                let d12 = hypot(p2.x - p1.x, p2.y - p1.y)
                
                var controlPoint1 = CGPoint.zero
                var controlPoint2 = CGPoint.zero
                
                if d01 + d12 != 0 {
                    controlPoint1.x = p1.x - smoothing * d01 / (d01 + d12) * (p2.x - p0.x)
                    controlPoint1.y = p1.y - smoothing * d01 / (d01 + d12) * (p2.y - p0.y)
                    
                    controlPoint2.x = p1.x + smoothing * d12 / (d01 + d12) * (p2.x - p0.x)
                    controlPoint2.y = p1.y + smoothing * d12 / (d01 + d12) * (p2.y - p0.y)
                } else {
                    controlPoint1 = p1
                    controlPoint2 = p1
                }
                return (controlPoint1, controlPoint2)
            }
            
            path.move(to: points[0])
            
            for i in 0..<points.count {
                let p0 = points[(i - 1 + points.count) % points.count]
                let p1 = points[i]
                let p2 = points[(i + 1) % points.count]
                
                let (cp1, cp2) = controlPoints(for: p0, p1, p2)
                path.addCurve(to: p2, control1: cp1, control2: cp2)
            }
            path.closeSubpath()
        }
    }
    
    func makeTailPath(from start: CGPoint, length: CGFloat, width: CGFloat, angle: Angle) -> Path {
        let tailLength = max(length, 1)
        let tailWidth = max(width, 1)
        
        let angleRad = angle.radians
        
        let endPoint = CGPoint(
            x: start.x + cos(angleRad) * tailLength,
            y: start.y + sin(angleRad) * tailLength
        )
        
        return Path { path in
            path.move(to: start)
            path.addQuadCurve(
                to: endPoint,
                control: CGPoint(
                    x: (start.x + endPoint.x) / 2 + sin(angleRad) * tailWidth / 2,
                    y: (start.y + endPoint.y) / 2 - cos(angleRad) * tailWidth / 2
                )
            )
            path.addLine(to: CGPoint(
                x: endPoint.x - sin(angleRad) * tailWidth / 2,
                y: endPoint.y + cos(angleRad) * tailWidth / 2
            ))
            path.addQuadCurve(
                to: start,
                control: CGPoint(
                    x: (start.x + endPoint.x) / 2 - sin(angleRad) * tailWidth / 2,
                    y: (start.y + endPoint.y) / 2 + cos(angleRad) * tailWidth / 2
                )
            )
            path.closeSubpath()
        }
    }
}

// MARK: - Controls view

struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title): \(String(format: "%.2f", value))")
                .font(.caption)
                .bold()
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Bool extension for probability

extension Bool {
    /// Returns true with the given probability (0...1)
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
