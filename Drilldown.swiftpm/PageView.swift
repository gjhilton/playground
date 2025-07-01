import UIKit
import AudioToolbox

// MARK: - UIColor Extension

extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .alphanumerics.inverted)
        guard let intVal = UInt64(hex.count == 6 ? "FF" + hex : hex, radix: 16) else {
            return nil
        }
        
        let a = CGFloat((intVal & 0xFF000000) >> 24) / 255
        let r = CGFloat((intVal & 0x00FF0000) >> 16) / 255
        let g = CGFloat((intVal & 0x0000FF00) >> 8) / 255
        let b = CGFloat(intVal & 0x000000FF) / 255
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - PageView Protocol

protocol PageView: UIView {
    init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void)
}

// MARK: - BasePageView

class BasePageView: UIView, PageView {
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hexString: data["backgroundColour"] as? String ?? "") ?? .white
        setupView(data: data, children: children)
        DispatchQueue.main.async(execute: callback)
    }
    
    func setupView(data: [String: Any], children: [PageData]?) {
        // To be overridden by subclasses for custom UI setup
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PlaceholderPageView

final class PlaceholderPageView: BasePageView {
    override func setupView(data: [String: Any], children: [PageData]?) {
        let label = UILabel()
        label.text = data["title"] as? String ?? "No Title"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - MenuPageView

final class MenuPageView: BasePageView {
    private var buttons: [UIButton] = []
    private var childrenData: [PageData] = []
    private var buttonCallback: ((PageData) -> Void)?
    
    override func setupView(data: [String: Any], children: [PageData]?) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        
        if let children = children {
            childrenData = children
            buttons = children.enumerated().map { index, child in
                let button = UIButton(type: .system)
                button.setTitle(child.label ?? "No Label", for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
                button.tag = index
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                stackView.addArrangedSubview(button)
                return button
            }
        }
    }
    
    func setButtonCallback(_ callback: @escaping (PageData) -> Void) {
        buttonCallback = callback
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        guard let pageData = childrenData[safe: sender.tag] else {
            print("Button index out of range")
            return
        }
        
        print("Button pressed for pageData: \(pageData)")
        AudioServicesPlaySystemSound(SystemSoundID(1104))
        buttonCallback?(pageData)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else {
            return nil
        }
        return self[index]
    }
}
