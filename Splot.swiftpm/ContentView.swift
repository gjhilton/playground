import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var splats: [Splat] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
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
                        splats.append(Splat.generate(center: location))
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
    
    struct Parameters {
        let centralRadiusRange: ClosedRange<CGFloat>
        let largeCountRange: ClosedRange<Int>
        let largeRadiusRange: ClosedRange<CGFloat>
        let largeDistanceRange: ClosedRange<CGFloat>
        let mediumCountRange: ClosedRange<Int>
        let mediumRadiusRange: ClosedRange<CGFloat>
        let mediumDistanceRange: ClosedRange<CGFloat>
        let smallCountRange: ClosedRange<Int>
        let smallRadiusRange: ClosedRange<CGFloat>
        let smallDistanceRange: ClosedRange<CGFloat>
        let splashCountRange: ClosedRange<Int>
        let splashLengthRange: ClosedRange<CGFloat>
        let splashWidthRange: ClosedRange<CGFloat>
        let splashDistanceRange: ClosedRange<CGFloat>
        let splashRotationJitter: ClosedRange<Double>
    }

    static let params = Parameters(
        centralRadiusRange: 30...50,
        largeCountRange: 0...3,
        largeRadiusRange: 15...25,
        largeDistanceRange: 12.5...33.75,
        mediumCountRange: 3...9,
        mediumRadiusRange: 8...19,
        mediumDistanceRange: 40...70,
        smallCountRange: 6...15,
        smallRadiusRange: 5...10,
        smallDistanceRange: 30...82.5,
        splashCountRange: 0...6,
        splashLengthRange: 20...60,
        splashWidthRange: 10...30,
        splashDistanceRange: 40...70,
        splashRotationJitter: -10...10
    )

    static func generate(center: CGPoint, params: Parameters = Splat.params) -> Splat {
        var dots: [SplatDot] = []
        // 1 large central dot
        let centralRadius = CGFloat.random(in: params.centralRadiusRange)
        dots.append(SplatDot(
            position: center,
            size: CGSize(width: centralRadius * 2, height: centralRadius * 2),
            isEllipse: false,
            rotation: 0
        ))
        // Large dots
        let largeCount = Int.random(in: params.largeCountRange)
        for _ in 0..<largeCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.largeDistanceRange)
            let radius = CGFloat.random(in: params.largeRadiusRange)
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
        let mediumCount = Int.random(in: params.mediumCountRange)
        for _ in 0..<mediumCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.mediumDistanceRange)
            let radius = CGFloat.random(in: params.mediumRadiusRange)
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
        let smallCount = Int.random(in: params.smallCountRange)
        for _ in 0..<smallCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.smallDistanceRange)
            let radius = CGFloat.random(in: params.smallRadiusRange)
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
        let splashCount = Int.random(in: params.splashCountRange)
        for _ in 0..<splashCount {
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: params.splashDistanceRange)
            let length = CGFloat.random(in: params.splashLengthRange)
            let width = CGFloat.random(in: params.splashWidthRange)
            let pos = CGPoint(
                x: center.x + cos(angle) * dist,
                y: center.y + sin(angle) * dist
            )
            // Rotate so the ellipse points away from the center (radiates out)
            let rotation = Double(angle * 180 / .pi) + Double.random(in: params.splashRotationJitter)
            dots.append(SplatDot(
                position: pos,
                size: CGSize(width: width, height: length),
                isEllipse: true,
                rotation: rotation
            ))
        }
        return Splat(center: center, dots: dots)
    }

    private init(center: CGPoint, dots: [SplatDot]) {
        self.center = center
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
