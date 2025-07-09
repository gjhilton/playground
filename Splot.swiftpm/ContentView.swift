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
                // Visualize splats as blue circles for now 
                
                ForEach(splats) { splat in
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .position(splat.location)
                }
                // Transparent overlay to capture taps and add splats
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { value in
                                // Get tap location in the view's coordinate space
                                if let window = UIApplication.shared.windows.first {
                                    let tapLocation = window.rootViewController?.view.gestureRecognizers?.first?.location(in: window.rootViewController?.view)
                                    // Instead, use geo.frame(in: .local) and .location from DragGesture
                                }
                            }
                    )
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        splats.append(Splat(id: UUID(), location: location))
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
    let id: UUID
    let location: CGPoint
}
