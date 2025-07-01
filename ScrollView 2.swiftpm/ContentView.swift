import SwiftUI
import UIKit
import AudioToolbox

// MARK: - Codable Data Model for JSON

struct CodablePageData: Codable {
    let viewClass: String?
    let label: String?
    let data: [String: CodableValue]?
    let children: [CodablePageData]?
}

// Wrapper to decode heterogenous JSON dictionary values
enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case object([String: CodableValue])
    case array([CodableValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: CodableValue].self) {
            self = .object(v)
        } else if let v = try? container.decode([CodableValue].self) {
            self = .array(v)
        } else {
            throw DecodingError.typeMismatch(CodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for CodableValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        case .object(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        }
    }
    
    // Convenience: convert to Any for usage
    var anyValue: Any? {
        switch self {
        case .string(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .bool(let v): return v
        case .null: return nil
        case .object(let v): return v.mapValues { $0.anyValue }
        case .array(let v): return v.compactMap { $0.anyValue }
        }
    }
}

// MARK: - PageData for runtime usage

struct PageData {
    let viewClass: String?
    let data: [String: Any]?
    let children: [PageData]?
    let label: String?
    
    init(from codable: CodablePageData) {
        viewClass = codable.viewClass
        label = codable.label
        if let codableData = codable.data {
            var tempDict = [String: Any]()
            for (key, value) in codableData {
                tempDict[key] = value.anyValue
            }
            data = tempDict
        } else {
            data = nil
        }
        if let codableChildren = codable.children {
            children = codableChildren.map { PageData(from: $0) }
        } else {
            children = nil
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

// MARK: - MenuPageView with callback

final class MenuPageView: UIView, PageView {
    private var buttons: [UIButton] = []
    private var childrenData: [PageData] = []
    private var buttonCallback: ((PageData) -> Void)?
    
    required init(data: [String: Any], children: [PageData]?, callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        // Default empty callback; will be set later
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
    
    // This will hold the root PageData loaded from JSON
    private var rootPageData: PageData?
    
    // Hardcoded JSON config string
    private let applicationConfigJSON = """
    {
        "viewClass": "MenuPageView",
        "children": [
            {
                "viewClass": "PlaceholderPageView",
                "label": "Tour",
                "data": {
                    "title": "Tour placeholder"
                }
            },
            {
                "viewClass": "PlaceholderPageView",
                "label": "Browse",
                "data": {
                    "title": "Browse placeholder"
                }
            },
            {
                "viewClass": "PlaceholderPageView",
                "label": "Extras",
                "data": {
                    "title": "Extras placeholder"
                }
            }
        ]
    }
    """
    
    init(initialViewClass: TitleScreenViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        super.init(frame: .zero)
        configure()
        layoutUI()
        addTitlePage()
        backgroundColor = .white
        
        loadConfigFromJSON()
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
        guard let root = rootPageData else {
            print("Root page data not loaded yet")
            return
        }
        if let page = createView(from: root) {
            appendPage(page)
            scrollToPage(index: 1)
        }
    }
    
    private func loadConfigFromJSON() {
        guard let jsonData = applicationConfigJSON.data(using: .utf8) else {
            print("Failed to convert JSON string to data")
            return
        }
        
        do {
            let codablePageData = try JSONDecoder().decode(CodablePageData.self, from: jsonData)
            rootPageData = PageData(from: codablePageData)
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
    
    private func createView(from pageData: PageData) -> UIView? {
        guard let viewClass = pageData.viewClass else {
            print("No viewClass in pageData")
            return nil
        }
        
        let pageViewType: PageView.Type?
        switch viewClass {
        case "PlaceholderPageView": pageViewType = PlaceholderPageView.self
        case "MenuPageView": pageViewType = MenuPageView.self
        default:
            print("Unknown viewClass: \(viewClass)")
            pageViewType = nil
        }
        
        guard let viewType = pageViewType else { return nil }
        let data = pageData.data ?? [:]
        let children = pageData.children
        
        let view = viewType.init(data: data, children: children) {}
        
        if let menuView = view as? MenuPageView {
            menuView.setButtonCallback { [weak self] selectedPageData in
                guard let self = self else { return }
                if let newPage = self.createView(from: selectedPageData) {
                    DispatchQueue.main.async {
                        self.appendPage(newPage)
                        self.scrollToPage(index: self.views.count - 1)
                    }
                }
            }
        }
        
        return view
    }
    
    private func appendPage(_ view: UIView) {
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
