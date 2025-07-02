import SwiftUI
import CoreText

class CoreTextUIView: UIView {
    private let attrString: NSAttributedString
    
    init(attributedString: NSAttributedString) {
        self.attrString = attributedString
        let size = CoreTextUIView.measure(attrString: attrString)
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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

struct AnimatedTextView: UIViewRepresentable {
    let text: String
    
    private var attributedString: NSAttributedString {
        AnimatedTextView.makeAttributedString(from: text)
    }
    
    private var intrinsicSize: CGSize {
        CoreTextUIView.measure(attrString: attributedString)
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

struct SplashScreenView: View {
    // Example arbitrary position (can be changed)
    @State private var textPosition = CGPoint(x: 200, y: 100)
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            AnimatedTextView(text: "Funeral Trousers")
                .frame(
                    width: CoreTextUIView.measure(attrString: AnimatedTextView.makeAttributedString(from: "Funeral Trousers")).width,
                    height: CoreTextUIView.measure(attrString: AnimatedTextView.makeAttributedString(from: "Funeral Trousers")).height
                )
                .position(textPosition)
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
