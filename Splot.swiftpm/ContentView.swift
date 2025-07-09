import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var splats: [Splat] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 24) {
                    Button("Button 1") {
                        playAlertSound()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                    Button("Button 2") {
                        playAlertSound()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
                }
                // Visualize splats as blue dots/ellipses
                ForEach(splats) { splat in
                    ForEach(splat.dots) { dot in
                        if dot.isEllipse {
                            Ellipse()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: dot.size.width, height: dot.size.height)
                                .position(dot.position)
                                .rotationEffect(.degrees(dot.rotation))
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: dot.size.width, height: dot.size.height)
                                .position(dot.position)
                        }
                    }
                }
                // Transparent overlay to capture taps and add splats
                Color.clear
                    .contentShape(Rectangle())
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        splats.append(Splat(center: location))
                    }
            )
        }
    }
    
    private func playAlertSound() {
        guard let systemSoundID = SystemSoundID(exactly: 1005) else { return } // 1005 is a standard alert sound
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

struct Splat: Identifiable {
    let id: UUID = UUID()
    let center: CGPoint
    let dots: [SplatDot]
    
    init(center: CGPoint) {
        self.center = center
        var dots: [SplatDot] = []
        // 1 large central dot (20–30px radius)
        let centralRadius = CGFloat.random(in: 20...30)
        dots.append(SplatDot(
            position: center,
            size: CGSize(width: centralRadius * 2, height: centralRadius * 2),
            isEllipse: false,
            rotation: 0
        ))
        // 0–3 large dots (15–25px radius, close to center)
        let largeCount = Int.random(in: 0...3)
        for _ in 0..<largeCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: 25...45)
            let radius = CGFloat.random(in: 15...25)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // 3–9 medium dots (8–19px radius, slightly wider radius)
        let mediumCount = Int.random(in: 3...9)
        for _ in 0..<mediumCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: 40...70)
            let radius = CGFloat.random(in: 8...19)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // 6–15 small dots (5–10px radius, wider still)
        let smallCount = Int.random(in: 6...15)
        for _ in 0..<smallCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: 60...110)
            let radius = CGFloat.random(in: 5...10)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: radius * 2, height: radius * 2),
                isEllipse: false,
                rotation: 0
            ))
        }
        // 0–6 splashes (ellipses, 10–30px, radiating from center)
        let splashCount = Int.random(in: 0...6)
        for _ in 0..<splashCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: 80...140)
            let length = CGFloat.random(in: 20...60)
            let width = CGFloat.random(in: 10...30)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let rotation = Double(angle * 180 / .pi) + Double.random(in: -10...10)
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: width, height: length),
                isEllipse: true,
                rotation: rotation
            ))
        }
        self.dots = dots
    }
}

struct SplatDot: Identifiable {
    let id: UUID = UUID()
    let position: CGPoint
    let size: CGSize
    let isEllipse: Bool
    let rotation: Double
}
