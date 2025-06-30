import SwiftUI
import UIKit

// Define the MenuNode structure, representing each menu item
struct MenuNode {
    let title: String
    let viewClass: UIView.Type
    let children: [MenuNode]
    var progress: Float
}

// Base class for creating a custom view for the title on page 1
final class TitleView: UIView {
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

// A view that renders the top menu (Tour, Browse, Extras) buttons
final class TopMenuView: UIView {
    let tourButton = UIButton(type: .system)
    let browseButton = UIButton(type: .system)
    let extrasButton = UIButton(type: .system)
    private let stackView = UIStackView()
    var onButtonTap: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        configure()
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func configure() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 40
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        tourButton.setTitle("Tour", for: .normal)
        browseButton.setTitle("Browse", for: .normal)
        extrasButton.setTitle("Extras", for: .normal)
        
        [tourButton, browseButton, extrasButton].forEach {
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .boldSystemFont(ofSize: 28)
            stackView.addArrangedSubview($0)
        }
        
        tourButton.addTarget(self, action: #selector(tourTapped), for: .touchUpInside)
        browseButton.addTarget(self, action: #selector(browseTapped), for: .touchUpInside)
        extrasButton.addTarget(self, action: #selector(extrasTapped), for: .touchUpInside)
    }
    
    private func layoutUI() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 60),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
        ])
    }
    
    @objc private func tourTapped() { onButtonTap?("Tour") }
    @objc private func browseTapped() { onButtonTap?("Browse") }
    @objc private func extrasTapped() { onButtonTap?("Extras") }
}

// View for other pages like the "Tour" or "Browse" pages
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

// The scrolling view that holds the dynamically created views based on the data
final class ScrollingView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var currentNode: MenuNode?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        layoutUI()
        addInitialViews()
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
        let titleView = TitleView(title: node.title)
        addView(titleView)
        
        // Add the top menu view
        let menuView = TopMenuView()
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
    
    // Load the tree structure from the data
    func loadTree(_ node: MenuNode) {
        currentNode = node
        
        // Reset views
        for view in views {
            view.removeFromSuperview()
        }
        views.removeAll()
        
        addInitialViews()
    }
}

// Example data for the menu
let rootNode = MenuNode(
    title: "Secret project",
    viewClass: TitleView.self,
    children: [
        MenuNode(
            title: "Tour",
            viewClass: PageView.self,
            children: [],
            progress: 0.5
        ),
        MenuNode(
            title: "Browse",
            viewClass: PageView.self,
            children: [],
            progress: 0.2
        ),
        MenuNode(
            title: "Extras",
            viewClass: PageView.self,
            children: [],
            progress: 0.8
        )
    ],
    progress: 0.0
)

struct ScrollingViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ScrollingView {
        let scrollView = ScrollingView()
        scrollView.loadTree(rootNode)
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
