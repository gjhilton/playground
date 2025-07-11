import SwiftUI
import UIKit

// MARK: - Configuration

final class ScrapAppearanceConfig {
    // Paper lightness range
    static let baseColorMin = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let baseColorMax = Color.white
    
    // Shadow
    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 12
    static let shadowOffset = CGSize(width: 6, height: 6)
    
    // Rotation
    static let maxRotationDegrees: Double = 4
    
    // Overlap
    static let overlapRange: ClosedRange<CGFloat> = -10 ... -4
    
    // Padding
    static let verticalPaddingCM: CGFloat = 28.35 // ~1 cm
    static let horizontalPadding: CGFloat = 16
    
    // Scrap size
    static let minScrapHeight: CGFloat = 120
    
    // Texture
    static let textureScale: CGFloat = 2.0
    static let textureSize = CGSize(width: 256, height: 256)
    static let speckleCount = 3000
    static let stainCount = 10
}

// MARK: - Scrap Model

struct Scrap: Identifiable {
    let id = UUID()
    let text: String
    let rotation: Angle
    let overlapOffset: CGFloat
    let backgroundColor: Color
    
    init(index: Int) {
        let words = loremIpsum.components(separatedBy: " ")
        let wordCount = Int.random(in: 20...50)
        self.text = words.shuffled().prefix(wordCount).joined(separator: " ")
        let direction = index % 2 == 0 ? 1.0 : -1.0
        self.rotation = Angle(degrees: direction * Double.random(in: 1...ScrapAppearanceConfig.maxRotationDegrees))
        self.overlapOffset = CGFloat.random(in: ScrapAppearanceConfig.overlapRange)
        
        self.backgroundColor = Color.lerp(
            from: ScrapAppearanceConfig.baseColorMin,
            to: ScrapAppearanceConfig.baseColorMax,
            fraction: Double.random(in: 0...1)
        )
    }
}

// MARK: - Views

struct ContentView: View {
    var body: some View {
        CollageView()
            .background(Color.gray.opacity(0.4))
    }
}

struct CollageView: View {
    let scraps = (0..<15).map { Scrap(index: $0) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(scraps) { scrap in
                    ScrapView(scrap: scrap)
                        .offset(y: scrap.overlapOffset)
                }
            }
        }
    }
}

struct ScrapView: View {
    let scrap: Scrap
    
    var body: some View {
        ZStack {
            CrumpledPaperView(baseColor: scrap.backgroundColor)
            Text(scrap.text)
                .padding(.vertical, ScrapAppearanceConfig.verticalPaddingCM)
                .padding(.horizontal, ScrapAppearanceConfig.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.black)
        }
        .frame(minHeight: ScrapAppearanceConfig.minScrapHeight)
        .rotationEffect(scrap.rotation)
        .shadow(color: ScrapAppearanceConfig.shadowColor,
                radius: ScrapAppearanceConfig.shadowRadius,
                x: ScrapAppearanceConfig.shadowOffset.width,
                y: ScrapAppearanceConfig.shadowOffset.height)
        .padding(.horizontal)
    }
}

// MARK: - Paper Background with Crumple, Noise, and Grime

struct CrumpledPaperView: View {
    let baseColor: Color
    
    var body: some View {
        let texture = PaperTextureGenerator.shared.textureImage
        
        Rectangle()
            .fill(baseColor)
            .overlay(
                Rectangle()
                    .fill(ImagePaint(image: texture, scale: ScrapAppearanceConfig.textureScale))
                    .blendMode(.multiply)
            )
            .overlay(
                WrinkleOverlay()
                    .blendMode(.multiply)
                    .opacity(0.10)
            )
            .overlay(
                InnerShadow()
            )
    }
}

// MARK: - Inner Shadow for Dirty Edges

struct InnerShadow: View {
    var body: some View {
        Rectangle()
            .stroke(Color.black.opacity(0.25), lineWidth: 2)
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 0)
            .clipShape(Rectangle())
            .mask(Rectangle().fill(LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .clear, location: 0.15),
                    .init(color: .clear, location: 0.85),
                    .init(color: .black, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )))
    }
}

// MARK: - Wrinkle Lines

struct WrinkleOverlay: View {
    let count = 10
    let length: CGFloat = 140
    
    var body: some View {
        Canvas { context, size in
            for _ in 0..<count {
                let start = CGPoint(
                    x: CGFloat.random(in: 0..<size.width),
                    y: CGFloat.random(in: 0..<size.height)
                )
                let angle = CGFloat.random(in: -0.3 ... 0.3)
                let end = CGPoint(
                    x: start.x + length * cos(angle),
                    y: start.y + length * sin(angle)
                )
                
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                
                context.stroke(path, with: .color(.brown.opacity(0.04)), lineWidth: CGFloat.random(in: 1...2))
            }
        }
    }
}

// MARK: - Paper Texture Generator (Noise + Stains)

class PaperTextureGenerator {
    static let shared = PaperTextureGenerator()
    let textureImage: Image
    
    private init() {
        let size = ScrapAppearanceConfig.textureSize
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            
            // Background fill
            context.setFillColor(UIColor(ScrapAppearanceConfig.baseColorMin).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            // Noise speckles
            for _ in 0..<ScrapAppearanceConfig.speckleCount {
                let dotSize = CGFloat.random(in: 0.5...2.5)
                let alpha = CGFloat.random(in: 0.01...0.08)
                let gray = CGFloat.random(in: 0.3...0.7)
                let color = UIColor(white: gray, alpha: alpha)
                
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                context.setFillColor(color.cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
            }
            
            // Brown stains
            for _ in 0..<ScrapAppearanceConfig.stainCount {
                let radius = CGFloat.random(in: 10...25)
                let center = CGPoint(
                    x: CGFloat.random(in: 0..<size.width),
                    y: CGFloat.random(in: 0..<size.height)
                )
                let color = UIColor(red: 0.75, green: 0.65, blue: 0.4, alpha: 0.07)
                let gradient = CGGradient(colorsSpace: nil,
                                          colors: [color.cgColor, UIColor.clear.cgColor] as CFArray,
                                          locations: [0,1])!
                context.drawRadialGradient(gradient,
                                           startCenter: center,
                                           startRadius: 0,
                                           endCenter: center,
                                           endRadius: radius / 2,
                                           options: .drawsAfterEndLocation)
            }
        }
        
        self.textureImage = Image(uiImage: image)
    }
}

// MARK: - Helpers

extension Color {
    static func lerp(from: Color, to: Color, fraction: Double) -> Color {
        let c1 = from.components()
        let c2 = to.components()
        
        return Color(
            red: c1.r + (c2.r - c1.r) * fraction,
            green: c1.g + (c2.g - c1.g) * fraction,
            blue: c1.b + (c2.b - c1.b) * fraction,
            opacity: c1.a + (c2.a - c1.a) * fraction
        )
    }
    
    func components() -> (r: Double, g: Double, b: Double, a: Double) {
#if canImport(UIKit)
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
#else
        return (0, 0, 0, 0)
#endif
    }
}

// MARK: - Ipsum

let loremIpsum = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum
"""

// MARK: - Preview

#Preview {
    ContentView()
}
