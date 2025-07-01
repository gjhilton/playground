import SwiftUI
import UIKit

struct TextScrapView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let isEditable: Bool
    let isScrollEnabled: Bool
    let borderPadding: CGFloat = 20
    
    private var calculatedHeight: CGFloat
    
    class Coordinator {
        var paperView: PaperTextureView?
        var textView: UITextView?
    }
    
    init(
        text: String,
        font: UIFont = UIFont.systemFont(ofSize: 16),
        isEditable: Bool = false,
        isScrollEnabled: Bool = true
    ) {
        self.text = text
        self.font = font
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self.calculatedHeight = TextScrapView.calculateHeight(for: text, font: font, borderPadding: borderPadding)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.8
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOffset = CGSize(width: 2, height: 2)
        containerView.layer.masksToBounds = false
        
        let paperView = PaperTextureView()
        paperView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(paperView)
        context.coordinator.paperView = paperView
        
        let textView = UITextView()
        textView.isEditable = isEditable
        textView.isScrollEnabled = isScrollEnabled
        textView.font = font
        textView.textColor = .black
        textView.backgroundColor = .clear
        textView.text = text
        textView.isSelectable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)
        context.coordinator.textView = textView
        
        NSLayoutConstraint.activate([
            paperView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paperView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paperView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            paperView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: borderPadding),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: borderPadding),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -borderPadding),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -borderPadding),
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        textView.text = text
        textView.font = font
        textView.isEditable = isEditable
        textView.isScrollEnabled = isScrollEnabled
    }
    
    func sizeThatFits(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: calculatedHeight)
    }
    
    static func calculateHeight(for text: String, font: UIFont, borderPadding: CGFloat) -> CGFloat {
        let textWidth = UIScreen.main.bounds.width * 0.9 - borderPadding * 2
        let constraintSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height) + borderPadding * 2
    }
}
