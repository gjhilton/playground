import UIKit

protocol TitlePageViewProtocol: UIView {
    var onReady: (() -> Void)? { get set }
    init(onReady: @escaping (() -> Void))
}

final class TitlePageView: UIView, TitlePageViewProtocol {
    private let label = UILabel()
    private let button = UIButton(type: .system)
    private let titleText: String = "Welcome to the App"
    private var isReady = false
    var onReady: (() -> Void)?
    
    required init(onReady: @escaping (() -> Void)) {
        self.onReady = onReady
        super.init(frame: .zero)
        backgroundColor = .white
        setupLabel()
        setupButton()
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel() {
        label.text = titleText
        label.font = .boldSystemFont(ofSize: 36)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupButton() {
        button.setTitle("Ready", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutUI() {
        addSubview(label)
        addSubview(button)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    @objc private func buttonTapped() {
        if !isReady {
            isReady = true
            button.removeFromSuperview()
            onReady?()
        }
    }
}
