import SwiftUI
import AVFoundation

// MARK: - TextView

final class TextView: UIView {
    private let text: String
    private let fontSize: CGFloat
    private let label: UILabel
    
    init(text: String, fontSize: CGFloat, position: CGPoint) {
        self.text = text
        self.fontSize = fontSize
        self.label = UILabel()
        let height = fontSize * 2
        let width: CGFloat = 300
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        backgroundColor = .red
        
        label.text = text
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        
        center = position
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func play() {
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
    
    func rewind() {
        AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
}

// MARK: - SplashscreenView

final class SplashscreenView: UIView {
    private let textView1: TextView
    private let textView2: TextView
    
    override init(frame: CGRect) {
        let xPos: CGFloat = 200
        let yPos: CGFloat = 200
        
        textView1 = TextView(text: "Funeral Trousers", fontSize: 18, position: CGPoint(x: xPos, y: yPos))
        textView2 = TextView(text: "presents", fontSize: 14, position: CGPoint(x: xPos, y: yPos + 30))
        
        super.init(frame: frame)
        backgroundColor = .white
        
        addSubview(textView1)
        addSubview(textView2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    private let splashscreen = SplashscreenViewRepresentable()
    
    var body: some View {
        VStack {
            splashscreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
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
        .padding(.horizontal, 20)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
