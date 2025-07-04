import SwiftUI

// MARK: - SplashscreenView

final class SplashscreenView: UIView {
    private let textView1: AnimatedTextView
    private let textView2: AnimatedTextView
    
    init() {
        let yPos: CGFloat = 200
        
        textView1 = AnimatedTextView(text: "FUNERAL TROUSERS", fontSize: 24, position: CGPoint(x: 400, y: yPos))
        textView2 = AnimatedTextView(text: "presents", fontSize: 18, position: CGPoint(x: 700, y: yPos + 40))
        
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        addSubview(textView1)
        addSubview(textView2)
    }
    
    func play() {
        textView1.play()
        textView2.play()
    }
    
    func rewind() {
        textView1.rewind()
        textView2.rewind()
    }
}

// MARK: - SplashscreenViewRepresentable

struct SplashscreenViewRepresentable: UIViewRepresentable {
    let splashscreenView = SplashscreenView()
    
    func makeUIView(context: Context) -> SplashscreenView {
        splashscreenView
    }
    
    func updateUIView(_ uiView: SplashscreenView, context: Context) {}
    
    func play() {
        splashscreenView.play()
    }
    
    func rewind() {
        splashscreenView.rewind()
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var isPlaying = false
    @State private var splashscreen = SplashscreenViewRepresentable()
    
    var body: some View {
        VStack {
            splashscreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            controlButtons
        }
        .padding(.horizontal, 20)
    }
    
    var controlButtons: some View {
        HStack(spacing: 40) {
            Button("Play") {
                splashscreen.play()
                isPlaying = true
            }
            .disabled(isPlaying)
            
            Button("Rewind") {
                splashscreen.rewind()
                isPlaying = false
            }
            .disabled(!isPlaying)
        }
        .padding(.bottom, 30)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
