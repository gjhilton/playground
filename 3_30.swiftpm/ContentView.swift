// Version: 3.30
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geo in
            if RenderingConstants.showParameterControls {
                // Editor mode: side-by-side layout
                SplatterEditorView()
            } else {
                // Production mode: clean overlay
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
                        Text(SplatterViewVersion.current)
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
}
