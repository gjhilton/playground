import SwiftUI
import UIKit

// MenuNode structure for tree data (now conforming to Codable)
struct MenuNode: Codable {
    let title: String
    let viewClass: String
    let children: [MenuNode]
    var progress: Float
}

// TitleScreen View for the initial page
final class TitleScreenView: UIView {
    private let label = UILabel()
    
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        
        label.text = title
        label.font = .boldSystemFont(ofSize: 36)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
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

// TopMenuView with data-driven buttons (vertical layout)
final class TopMenuView: UIView {
    private let stackView = UIStackView()
    var onButtonTap: ((String) -> Void)?
    
    // Initializer with child nodes to dynamically create buttons
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
        stackView.axis = .vertical  // Change to vertical layout
        stackView.distribution = .fill
        stackView.spacing = 20  // Space between buttons
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutUI(children: [MenuNode]) {
        addSubview(stackView)
        
        // Dynamically create buttons based on child nodes
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

// The scrolling view holding the pages (with array of views to maintain state)
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
        // Add the initial title view (this could be dynamically updated later)
        guard let node = currentNode else { return }
        let titleScreenView = TitleScreenView(title: node.title)
        addView(titleScreenView)
        
        // Add the top menu view based on the children of the current node
        let menuView = TopMenuView(children: node.children)
        menuView.onButtonTap = { [weak self] label in
            self?.handleMenuTap(label: label)
        }
        addView(menuView)
    }
    
    private func handleMenuTap(label: String) {
        // Remove existing page views if present
        while views.count > 2 {
            let view = views.removeLast()
            view.removeFromSuperview()
        }
        
        // Add a new page view for the tapped label
        let pageView = PageView(title: label)
        addView(pageView)
        
        // Scroll to the newly added page view
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
    
    // Load the tree structure from the parsed data
    func loadTree(_ node: MenuNode) {
        currentNode = node
        
        // Reset views
        for view in views {
            view.removeFromSuperview()
        }
        views.removeAll()
        
        addInitialViews()
    }
    
    // Parse the JSON string into MenuNode
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

// JSON data for the menu structure (passed from ContentView)
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
