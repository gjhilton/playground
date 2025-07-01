import SwiftUI
import UIKit
import AudioToolbox

import UIKit

protocol TitleScreenViewProtocol: UIView {
    var onReady: (() -> Void)? { get set }
    init(onReady: @escaping (() -> Void))
}

final class TitleScreenView: UIView, TitleScreenViewProtocol {
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

struct CodablePageData: Codable {
    let viewClass: String?
    let label: String?
    let data: [String: CodableValue]?
    let children: [CodablePageData]?
}

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

final class ApplicationView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var initialViewClass: TitleScreenViewProtocol.Type
    
    private var rootPageData: PageData?
    
    private let applicationConfigJSON = """
    {
        "viewClass": "MenuPageView",
        "children": [
            {
                "viewClass": "MenuPageView",
                "label": "Tour",
                "children": [
                    {
                        "viewClass": "PlaceholderPageView",
                        "label": "Location A",
                        "data": {
                            "title": "Location A"
                        }
                    },
                    {
                        "viewClass": "PlaceholderPageView",
                        "label": "Location B",
                        "data": {
                            "title": "Location B"
                        }
                    }
                ]
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
            menuView.setButtonCallback { [weak self, weak view] selectedPageData in
                guard let self = self else { return }
                guard let currentView = view else { return }
                guard let currentIndex = self.views.firstIndex(of: currentView) else { return }
                
                self.removePages(startingAt: currentIndex + 1)
                
                if let newPage = self.createView(from: selectedPageData) {
                    self.appendPage(newPage)
                    self.scrollToPage(index: self.views.count - 1)
                }
            }
        }
        
        return view
    }
    
    private func removePages(startingAt index: Int) {
        guard index < views.count else { return }
        let range = index..<views.count
        let viewsToRemove = views[range]
        
        for view in viewsToRemove {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        views.removeSubrange(range)
    }
    
    private func appendPage(_ view: UIView) {
        views.append(view)
        stackView.addArrangedSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    private func scrollToPage(index: Int) {
        guard index < views.count else { return }
        let width = scrollView.frame.size.width
        let offsetX = CGFloat(index) * width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
}

///
/// IMPORTANT: Do NOT change this struct! Always include it exactly as is.
/// This struct wraps the UIKit ApplicationView for use in SwiftUI.
/// Any modification to this may break functionality.
///
struct ApplicationViewRepresentable: UIViewRepresentable {
    // Do not modify the initialViewClass here.
    let initialViewClass: TitleScreenViewProtocol.Type
    
    func makeUIView(context: Context) -> ApplicationView {
        return ApplicationView(initialViewClass: initialViewClass)
    }
    
    func updateUIView(_ uiView: ApplicationView, context: Context) {
        // No update logic needed.
    }
}

///
/// IMPORTANT: Do NOT change this struct! Always include it exactly as is.
/// This is the SwiftUI ContentView wrapping ApplicationViewRepresentable.
/// Any modification to this may break functionality.
///
struct ContentView: View {
    var body: some View {
        ApplicationViewRepresentable(initialViewClass: TitleScreenView.self)
    }
}
