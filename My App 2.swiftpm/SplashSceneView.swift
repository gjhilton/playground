// splashsceneview.swift

import UIKit

class SplashSceneView: UIView {
    var duration: TimeInterval { 0 }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplashScenePresents: SplashSceneView {
    override var duration: TimeInterval { 10 }
    
    override init() {
        super.init()
        let label = UILabel()
        label.text = "Presents"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplashSceneTitle: SplashSceneView {
    override var duration: TimeInterval { 4 }
    
    override init() {
        super.init()
        let label = UILabel()
        label.text = "Title Screen"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
