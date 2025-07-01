import UIKit
import AudioToolbox

extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .alphanumerics.inverted)
        if hex.count == 6 {
            hex = "FF" + hex
        }
        guard hex.count == 8, let intVal = UInt64(hex, radix: 16) else {
            return nil
        }
        
        let a = CGFloat((intVal & 0xFF000000) >> 24) / 255
        let r = CGFloat((intVal & 0x00FF0000) >> 16) / 255
        let g = CGFloat((intVal & 0x0000FF00) >> 8) / 255
        let b = CGFloat(intVal & 0x000000FF) / 255
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

protocol PageView where Self: UIView {
    init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void)
}

final class PlaceholderPageView: UIView, PageView {
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        if let hex = data["backgroundColour"] as? String,
           let color = UIColor(hexString: hex) {
            backgroundColor = color
        } else {
            backgroundColor = .white
        }
        
        let title = data["title"] as? String ?? "No Title"
        
        let label = UILabel()
        label.text = title
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        DispatchQueue.main.async {
            callback()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MenuPageView: UIView, PageView {
    private var buttons: [UIButton] = []
    private var childrenData: [PageData] = []
    private var buttonCallback: ((PageData) -> Void)?
    
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        buttonCallback = nil
        
        backgroundColor = .white
        
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
            for (index, child) in children.enumerated() {
                let label = child.label ?? "No Label"
                let button = UIButton(type: .system)
                button.setTitle(label, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
                button.tag = index
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                buttons.append(button)
                stackView.addArrangedSubview(button)
            }
        }
        
        DispatchQueue.main.async {
            callback()
        }
    }
    
    func setButtonCallback(_ callback: @escaping (PageData) -> Void) {
        self.buttonCallback = callback
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        let index = sender.tag
        guard index < childrenData.count else {
            print("Button index out of range")
            return
        }
        
        let pageData = childrenData[index]
        print("Button pressed for pageData: \(pageData)")
        AudioServicesPlaySystemSound(SystemSoundID(1104))
        
        buttonCallback?(pageData)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

