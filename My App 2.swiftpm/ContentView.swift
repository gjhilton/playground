
import SwiftUI
import UIKit

// MARK: - Root Content View

struct ContentView: View {
    var body: some View {
        CollageView()
            .background(Color.gray.opacity(0.4)) // Mid gray background
    }
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
        self.rotation = Angle(degrees: direction * Double.random(in: 1...4))
        self.overlapOffset = CGFloat.random(in: -10 ... -4)
        
        // Background: nearly white with minor cream variation
        let almostWhite = Color.white
        let veryPaleCream = Color(red: 0.99, green: 0.98, blue: 0.95)
        self.backgroundColor = Color.lerp(from: veryPaleCream, to: almostWhite, fraction: Double.random(in: 0...1))
    }
}

// MARK: - Collage View

struct CollageView: View {
    let scraps: [Scrap] = (0..<15).map { Scrap(index: $0) }
    
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

// MARK: - Scrap View

struct ScrapView: View {
    let scrap: Scrap
    
    var body: some View {
        ZStack {
            CrumpledPaperBackground(baseColor: scrap.backgroundColor)
            Text(scrap.text)
                .padding(.vertical, 28.35) // 1cm top/bottom inside scrap
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.black)
        }
        .frame(minHeight: 120)
        .rotationEffect(scrap.rotation)
        // Bolder, darker, bigger drop shadow
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 6, y: 6)
        .padding(.horizontal)
    }
}

// MARK: - Crumpled Paper Background (smaller scale texture & lighter base color)

struct CrumpledPaperBackground: View {
    var baseColor: Color
    
    var body: some View {
        let texture = PaperTextureManager.shared.getTexture()
        
        Rectangle()
            .fill(baseColor)
            .overlay(
                Rectangle()
                    .fill(ImagePaint(image: texture, scale: 2.0)) // scale 2.0 = smaller texture details
                    .blendMode(.multiply)
            )
            .overlay(
                WrinkleLines()
                    .blendMode(.multiply)
                    .opacity(0.10)
            )
            .overlay(
                InnerShadow()
            )
    }
}

// MARK: - Inner Shadow (Grimy page edges)

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

// MARK: - Wrinkle Lines View

struct WrinkleLines: View {
    let lineCount = 10
    let lineLength: CGFloat = 140
    
    var body: some View {
        Canvas { context, size in
            for _ in 0..<lineCount {
                let xStart = CGFloat.random(in: 0...size.width)
                let yStart = CGFloat.random(in: 0...size.height)
                let angle = CGFloat.random(in: -0.3 ... 0.3)
                
                var path = Path()
                path.move(to: CGPoint(x: xStart, y: yStart))
                path.addLine(to: CGPoint(x: xStart + lineLength * cos(angle), y: yStart + lineLength * sin(angle)))
                
                context.stroke(path, with: .color(.brown.opacity(0.04)), lineWidth: CGFloat.random(in: 1...2))
            }
        }
    }
}

// MARK: - Paper Texture Manager (finer dirt & noise with lighter opacity)

class PaperTextureManager {
    static let shared = PaperTextureManager()
    
    private var cachedImage: Image? = nil
    private let textureSize = CGSize(width: 256, height: 256) // higher res for smaller scale texture
    
    private init() {
        generateAndCacheTexture()
    }
    
    private func generateAndCacheTexture() {
        let renderer = UIGraphicsImageRenderer(size: textureSize)
        let uiImage = renderer.image { ctx in
            let context = ctx.cgContext
            // Base nearly white pale cream color
            context.setFillColor(UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1.0).cgColor)
            context.fill(CGRect(origin: .zero, size: textureSize))
            
            // Smaller, denser noise: 3000 speckles, size 0.5 to 2.5, lighter opacity
            for _ in 0..<3000 {
                let x = CGFloat.random(in: 0..<textureSize.width)
                let y = CGFloat.random(in: 0..<textureSize.height)
                let dotSize = CGFloat.random(in: 0.5...2.5)
                let alpha = CGFloat.random(in: 0.01...0.08)
                let gray = CGFloat.random(in: 0.3...0.7)
                context.setFillColor(UIColor(white: gray, alpha: alpha).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
            }
            
            // Fewer and lighter brown stains (10), radius 10-25, lower opacity
            for _ in 0..<10 {
                let x = CGFloat.random(in: 0..<textureSize.width)
                let y = CGFloat.random(in: 0..<textureSize.height)
                let radius = CGFloat.random(in: 10...25)
                let color = UIColor(red: 0.75, green: 0.65, blue: 0.4, alpha: 0.07)
                let gradient = CGGradient(colorsSpace: nil,
                                          colors: [color.cgColor, UIColor.clear.cgColor] as CFArray,
                                          locations: [0,1])!
                context.drawRadialGradient(gradient,
                                           startCenter: CGPoint(x: x, y: y),
                                           startRadius: 0,
                                           endCenter: CGPoint(x: x, y: y),
                                           endRadius: radius/2,
                                           options: .drawsAfterEndLocation)
            }
        }
        
        self.cachedImage = Image(uiImage: uiImage)
    }
    
    func getTexture() -> Image {
        cachedImage ?? Image(systemName: "exclamationmark.triangle")
    }
}

// MARK: - Linear interpolation helper for Color

extension Color {
    static func lerp(from: Color, to: Color, fraction: Double) -> Color {
        let fromComponents = from.components()
        let toComponents = to.components()
        
        let r = fromComponents.r + (toComponents.r - fromComponents.r) * fraction
        let g = fromComponents.g + (toComponents.g - fromComponents.g) * fraction
        let b = fromComponents.b + (toComponents.b - fromComponents.b) * fraction
        let a = fromComponents.a + (toComponents.a - fromComponents.a) * fraction
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
    
    private func components() -> (r: Double, g: Double, b: Double, a: Double) {
#if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
#else
        return (0, 0, 0, 0) // fallback for macOS if needed
#endif
    }
}

// MARK: - Lorem Ipsum Source

let loremIpsum = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum
"""

// MARK: - Preview

#Preview {
    ContentView()
}
