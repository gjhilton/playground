import SwiftUI
import UIKit
import AudioToolbox

// MARK: - Data Model

struct PageData {
    let viewClass: String?
    let data: [String: Any]?
    let children: [PageData]?
    let label: String?
    
    // Helper to map string class names to PageView types
    func viewType() -> PageView.Type? {
        guard let viewClass = viewClass else { return nil }
        switch viewClass {
        case "PlaceholderPageView": return PlaceholderPageView.self
        case "MenuPageView": return MenuPageView.self
        default: return nil
        }
    }
}

// MARK: - PageView Protocol

protocol PageView where Self: UIView {
    init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void)
}

// MARK: - PlaceholderPageView

final class PlaceholderPageView: UIView, PageView {
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        // Set background color from data or default white
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

// MARK: - MenuPageView

final class MenuPageView: UIView, PageView {
    private var buttons: [UIButton] = []
    
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
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
            for child in children {
                let label = child.label ?? "No Label"
                let button = UIButton(type: .system)
                button.setTitle(label, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
                button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
                buttons.append(button)
                stackView.addArrangedSubview(button)
            }
        }
        
        DispatchQueue.main.async {
            callback()
        }
    }
    
    @objc private func buttonPressed() {
        AudioServicesPlaySystemSound(SystemSoundID(1104)) // Alert sound
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .alphanumerics.inverted)
        if hex.count == 6 {
            hex = "FF" + hex  // Assume alpha if missing
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

// MARK: - ApplicationView

final class ApplicationView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var initialViewClass: TitleScreenViewProtocol.Type
    
    // Hardcoded pageLookup for demo; normally loaded from JSON config
    let pageLookup: [String: PageData] = [
        "root": PageData(
            viewClass: "MenuPageView",
            data: nil,
            children: [
                PageData(viewClass: "PlaceholderPageView", data: ["title": "Tour placeholder"], children: nil, label: "Tour"),
                PageData(viewClass: "PlaceholderPageView", data: ["title": "Browse placeholder"], children: nil, label: "Browse"),
                PageData(viewClass: "PlaceholderPageView", data: ["title": "Extras placeholder"], children: nil, label: "Extras")
            ],
            label: nil
        )
    ]
    
    init(initialViewClass: TitleScreenViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        super.init(frame: .zero)
        configure()
        layoutUI()
        addTitlePage()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
    }
    
    private func layoutUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    private func addTitlePage() {
        let titleScreenView = initialViewClass.init(onReady: { [weak self] in
            self?.addRootPage()
        })
        appendPage(titleScreenView)
    }
    
    private func addRootPage() {
        createAndAppendPage(pageID: "root")
        scrollToPage(index: 1)
    }
    
    func createAndAppendPage(pageID: String) {
        if let pageData = pageLookup[pageID], let page = createView(from: pageData) {
            appendPage(page)
        }
    }
    
    private func createView(from pageData: PageData) -> UIView? {
        guard let viewType = pageData.viewType() else {
            print("Unknown viewClass: \(pageData.viewClass ?? "nil")")
            return nil
        }
        
        let dataDict = pageData.data ?? [:]
        let children = pageData.children
        
        return viewType.init(data: dataDict, children: children, callback: {})
    }
    
    func appendPage(_ view: UIView) {
        stackView.addArrangedSubview(view)
        views.append(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
    }
    
    private func scrollToPage(index: Int) {
        let offset = CGFloat(index) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }
}

// MARK: - SwiftUI Integration

struct ApplicationViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ApplicationView {
        ApplicationView(initialViewClass: TitleScreenView.self)
    }
    
    func updateUIView(_ uiView: ApplicationView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        ApplicationViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
