import SwiftUI
import UIKit

// Protocol for TitleScreenView implementations
protocol TitleScreenViewProtocol {
    var onReady: (() -> Void)? { get set }
    init(onReady: @escaping (() -> Void))
}

// MenuNode structure for tree data (now conforming to Codable)
struct MenuNode: Codable {
    let title: String
    let viewClass: String
    let children: [MenuNode]
    var progress: Float
}

// TitleScreenView for the initial page (Updated to "Ready" and improved encapsulation)
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

// TopMenuView with data-driven buttons (vertical layout)
final class TopMenuView: UIView {
    private let stackView = UIStackView()
    var onButtonTap: ((String) -> Void)?
    
    init(children: [MenuNode]) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        configure()
        layoutUI(children: children)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func configure() {
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutUI(children: [MenuNode]) {
        addSubview(stackView)
        
        children.forEach { child in
            let button = UIButton(type: .system)
            button.setTitle(child.title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 28)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        onButtonTap?(title)
    }
}

// View for other pages like "Tour", "Browse", etc.
final class PageView: UIView {
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .systemBlue
        
        let label = UILabel()
        label.text = "\(title) Menu"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

// The scrolling view holding the pages
final class ScrollingView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var currentNode: MenuNode?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
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
    
    private func addInitialViews() {
        guard let node = currentNode else { return }
        let titleView = TitleScreenView(onReady: { [weak self] in
            self?.addFirstMenu()
            self?.scrollToPage(index: 1)
        })
        addView(titleView)
    }
    
    private func addFirstMenu() {
        guard let node = currentNode else { return }
        
        let menuView = TopMenuView(children: node.children)
        menuView.onButtonTap = { [weak self] label in
            self?.handleMenuTap(label: label)
        }
        addView(menuView)
    }
    
    private func handleMenuTap(label: String) {
        while views.count > 2 {
            let view = views.removeLast()
            view.removeFromSuperview()
        }
        
        let pageView = PageView(title: label)
        addView(pageView)
        
        DispatchQueue.main.async {
            self.scrollToPage(index: 2)
        }
    }
    
    private func addView(_ view: UIView) {
        stackView.addArrangedSubview(view)
        views.append(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
    }
    
    private func scrollToPage(index: Int) {
        let offset = CGFloat(index) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }
    
    func loadTree(_ node: MenuNode) {
        currentNode = node
        
        for view in views {
            view.removeFromSuperview()
        }
        views.removeAll()
        
        addInitialViews()
    }
    
    func parseMenuData(from jsonString: String) -> MenuNode? {
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let menuData = try decoder.decode(MenuNode.self, from: data)
            return menuData
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}

// JSON data for the menu structure
let jsonData = """
{
    "title": "Home",
    "viewClass": "TitleScreenView",
    "children": [
        {
            "title": "Tour",
            "viewClass": "PageView",
            "children": [],
            "progress": 0.5
        },
        {
            "title": "Browse",
            "viewClass": "PageView",
            "children": [],
            "progress": 0.2
        },
        {
            "title": "Extras",
            "viewClass": "PageView",
            "children": [],
            "progress": 0.8
        }
    ],
    "progress": 0.0
}
"""

struct ScrollingViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ScrollingView {
        let scrollView = ScrollingView()
        if let rootNode = scrollView.parseMenuData(from: jsonData) {
            scrollView.loadTree(rootNode)
        }
        return scrollView
    }
    
    func updateUIView(_ uiView: ScrollingView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        ScrollingViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
