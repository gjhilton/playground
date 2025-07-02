import AVFoundation
import  UIKit

final class AnimatedTextView: UIView {
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
