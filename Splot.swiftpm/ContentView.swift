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
                                .fill(Color.blue.opacity(1))
                                .frame(width: dot.size.width, height: dot.size.height)
                                .position(dot.position)
                                .rotationEffect(.degrees(dot.rotation))
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(1))
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
    
    // MARK: - Splat Parameters
    static let centralRadiusRange: ClosedRange<CGFloat> = 20...30
    static let largeCountRange: ClosedRange<Int> = 0...3
    static let largeRadiusRange: ClosedRange<CGFloat> = 15...25
    static let largeDistanceRange: ClosedRange<CGFloat> = 12.5...22.5
    static let mediumCountRange: ClosedRange<Int> = 3...9
    static let mediumRadiusRange: ClosedRange<CGFloat> = 8...19
    static let mediumDistanceRange: ClosedRange<CGFloat> = 20...35
    static let smallCountRange: ClosedRange<Int> = 6...15
    static let smallRadiusRange: ClosedRange<CGFloat> = 5...10
    static let smallDistanceRange: ClosedRange<CGFloat> = 30...55
    static let splashCountRange: ClosedRange<Int> = 0...6
    static let splashLengthRange: ClosedRange<CGFloat> = 20...60
    static let splashWidthRange: ClosedRange<CGFloat> = 10...30
    static let splashDistanceRange: ClosedRange<CGFloat> = 40...70
    static let splashRotationJitter: ClosedRange<Double> = -10...10

    init(center: CGPoint) {
        self.center = center
        var dots: [SplatDot] = []
        // 1 large central dot
        let centralRadius = CGFloat.random(in: Splat.centralRadiusRange)
        dots.append(SplatDot(
            position: center,
            size: CGSize(width: centralRadius * 2, height: centralRadius * 2),
            isEllipse: false,
            rotation: 0
        ))
        // Large dots
        let largeCount = Int.random(in: Splat.largeCountRange)
        for _ in 0..<largeCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: Splat.largeDistanceRange)
            let radius = CGFloat.random(in: Splat.largeRadiusRange)
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
        // Medium dots
        let mediumCount = Int.random(in: Splat.mediumCountRange)
        for _ in 0..<mediumCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: Splat.mediumDistanceRange)
            let radius = CGFloat.random(in: Splat.mediumRadiusRange)
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
        // Small dots
        let smallCount = Int.random(in: Splat.smallCountRange)
        for _ in 0..<smallCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: Splat.smallDistanceRange)
            let radius = CGFloat.random(in: Splat.smallRadiusRange)
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
        // Splashes (ellipses)
        let splashCount = Int.random(in: Splat.splashCountRange)
        for _ in 0..<splashCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: Splat.splashDistanceRange)
            let length = CGFloat.random(in: Splat.splashLengthRange)
            let width = CGFloat.random(in: Splat.splashWidthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            let rotation = Double(angle * 180 / .pi) + Double.random(in: Splat.splashRotationJitter)
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
