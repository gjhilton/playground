import UIKit
import SwiftUI

// Your UIKit view
class ContentView: UIView {
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.text = "Hello UIKit"
        lbl.font = .systemFont(ofSize: 24, weight: .bold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// SwiftUI wrapper to display your UIKit view
struct ContentViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> ContentView {
        ContentView(frame: .zero)
    }
    
    func updateUIView(_ uiView: ContentView, context: Context) {}
}
