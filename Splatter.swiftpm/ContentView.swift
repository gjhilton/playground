// Version: 2.14
import SwiftUI

struct ContentView: View {
    @StateObject private var splatterView = SplatterView()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    Spacer()
                    Button("Clear Splats") {
                        splatterView.clear()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .foregroundColor(.white)
                    .font(.title2)
                    Spacer()
                    Text("2.14")
                        .font(.system(size: 36, weight: .regular, design: .default))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                }
                // Splatter overlay with Metal rendering
                SplatterViewUI(splatterView: splatterView)
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        splatterView.touched(center: value.location)
                    }
            )
        }
    }
}
