// Version: 2.86
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    Spacer()
                    Button("Clear Splats") {
                        NotificationCenter.default.post(name: .init("SplatterClear"), object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .foregroundColor(.white)
                    .font(.title2)
                    Spacer()
                    Text("2.86")
                        .font(.system(size: 36, weight: .regular, design: .default))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                }
                // Splatter overlay with Metal rendering
                SplatterView()
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        NotificationCenter.default.post(name: .init("SplatterAddSplat"), object: value.location)
                    }
            )
        }
    }
}
