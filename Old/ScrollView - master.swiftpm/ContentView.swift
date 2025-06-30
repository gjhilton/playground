import SwiftUI
import UIKit

class ScrollingView: UIView {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Setup scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            // Pin scrollView to edges of ScrollingView
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isPagingEnabled = false // Optional, depending on if you want snapping or free scroll
        
        // Setup stack view for horizontal layout
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fillEqually
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentStackView)
        
        // Pin stack view to scrollView content layout guide
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            
            // Make stackView height equal to scrollView frame height to avoid vertical scrolling
            contentStackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
        
        // Add some demo views
        for i in 1...5 {
            let demoView = UIView()
            demoView.backgroundColor = UIColor(
                hue: CGFloat(i) * 0.15,
                saturation: 0.8,
                brightness: 0.9,
                alpha: 1.0)
            
            // Each view will fill equally horizontally due to stackView settings
            
            contentStackView.addArrangedSubview(demoView)
            
            // We'll need to fix the width of each view equal to scrollView frame width,
            // because stackView will size arranged views automatically,
            // but the scrollView doesn't know its width at layout time, so we update later.
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Fix width of each arrangedSubview equal to scrollView's frame width
        for view in contentStackView.arrangedSubviews {
            view.widthAnchor.constraint(equalToConstant: scrollView.frame.width).isActive = true
        }
    }
}

struct ScrollingViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ScrollingView {
        return ScrollingView()
    }
    
    func updateUIView(_ uiView: ScrollingView, context: Context) {
        // No updates needed for now
    }
}

struct ContentView: View {
    var body: some View {
        ScrollingViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
