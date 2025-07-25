// Version: 2.73
import SwiftUI

// MARK: - Configuration Mode Toggle
// Configuration mode is controlled in SplatterView.swift

struct ContentView: View {
    @StateObject private var splatterViewModel = SplatterViewModel()
    
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
                    Text("2.73")
                        .font(.system(size: 36, weight: .regular, design: .default))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                }
                // Splatter editor with sidebar on iPad landscape
                SplatterEditorView(viewModel: splatterViewModel)
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
