import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            // Simple animated text views
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Title
                    AnimatedTextViewRepresentable(
                        text: "FUNERAL TROUSERS",
                        fontSize: 24,
                        position: CGPoint(x: 400, y: 100)
                    )
                    .frame(width: 800, height: 100)
                    
                    // Subtitle
                    AnimatedTextViewRepresentable(
                        text: "presents",
                        fontSize: 18,
                        position: CGPoint(x: 700, y: 140)
                    )
                    .frame(width: 800, height: 100)
                }
            }
            .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 40) {
                Button("Play") {
                    isPlaying = true
                }
                .disabled(isPlaying)
                .buttonStyle(.borderedProminent)
                
                Button("Rewind") {
                    isPlaying = false
                }
                .disabled(!isPlaying)
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Animated Text View Representable

struct AnimatedTextViewRepresentable: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let position: CGPoint
    
    func makeUIView(context: Context) -> AnimatedTextView {
        AnimatedTextView(
            text: text,
            fontSize: fontSize,
            position: position
        )
    }
    
    func updateUIView(_ uiView: AnimatedTextView, context: Context) {}
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
