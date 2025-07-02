import SwiftUI
import CoreText

// UIView that draws Core Text attributed string
class CoreTextUIView: UIView {
    private let attrString: NSAttributedString
    
    init(attributedString: NSAttributedString) {
        self.attrString = attributedString
        let size = CoreTextUIView.measure(attrString: attrString)
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    static func measure(attrString: NSAttributedString) -> CGSize {
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrString.length), nil, maxSize, nil)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1, y: -1)
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
        CTFrameDraw(frame, ctx)
    }
}

// SwiftUI wrapper for CoreTextUIView
struct AnimatedTextView: UIViewRepresentable {
    let text: String
    private let attributedString: NSAttributedString
    let intrinsicSize: CGSize
    
    init(text: String) {
        self.text = text
        self.attributedString = AnimatedTextView.makeAttributedString(from: text)
        self.intrinsicSize = CoreTextUIView.measure(attrString: attributedString)
    }
    
    func makeUIView(context: Context) -> CoreTextUIView {
        CoreTextUIView(attributedString: attributedString)
    }
    
    func updateUIView(_ uiView: CoreTextUIView, context: Context) {
        // Immutable text — no updates needed
    }
}

extension AnimatedTextView {
    static func makeAttributedString(from string: String) -> NSAttributedString {
        let font = CTFontCreateWithName("TimesNewRomanPSMT" as CFString, 36, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }
}

// Splash screen with AnimatedTextView and animation buttons
struct SplashScreenView: View {
    @State private var textPosition = CGPoint(x: 100, y: 100)
    @State private var opacity: Double = 0
    
    private let animatedText = AnimatedTextView(text: "Funeral Trousers")
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            animatedText
                .frame(width: animatedText.intrinsicSize.width, height: animatedText.intrinsicSize.height)
                .position(textPosition)
                .opacity(opacity)
            
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button("Animate Opacity") {
                        opacity = 0
                        withAnimation(.linear(duration: 1)) {
                            opacity = 1
                        }
                    }
                    Button("Reset") {
                        withAnimation(nil) {
                            opacity = 0
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        SplashScreenView()
    }
}

#Preview {
    ContentView()
}
