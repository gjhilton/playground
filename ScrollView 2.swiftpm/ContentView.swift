import SwiftUI
import UIKit

// MARK: - Data Model

struct PageData {
    let viewClass: PageView.Type?   // Reference to the UIView class implementing PageView
    let data: [String: Any]?
    let childPages: [PageData]?
    let label: String?
}

// MARK: - PageView Protocol

protocol PageView where Self: UIView {
    init(data: [String: Any], callback: @escaping () -> Void)
}

// MARK: - PlaceholderPageView

final class PlaceholderPageView: UIView, PageView {
    required init(data: [String: Any], callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        // Set background color from data or default to white
        if let hex = data["backgroundColour"] as? String,
           let color = UIColor(hexString: hex) {
            self.backgroundColor = color
        } else {
            self.backgroundColor = .white
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

// MARK: - MenuPageView (identical to PlaceholderPageView for now)

final class MenuPageView: UIView, PageView {
    required init(data: [String: Any], callback: @escaping () -> Void) {
        super.init(frame: .zero)
        
        if let hex = data["backgroundColour"] as? String,
           let color = UIColor(hexString: hex) {
            self.backgroundColor = color
        } else {
            self.backgroundColor = .white
        }
        
        let title = data["title"] as? String ?? "Menu"
        
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
    
    let pageLookup: [String: PageData] = [
        "0000001": PageData(
            viewClass: PlaceholderPageView.self,
            data: ["title": "Placeholder page"],
            childPages: nil,
            label: nil
        ),
        "root": PageData(
            viewClass: MenuPageView.self,
            data: ["title": "Menu page", "backgroundColour": "#FFD700"],
            childPages: nil,
            label: nil
        )
    ]
    
    init(initialViewClass: TitleScreenViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        super.init(frame: .zero)
        configure()
        layoutUI()
        addTitlePage()
        self.backgroundColor = .white
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
        if let page = createPage(pageID: pageID) {
            appendPage(page)
        }
    }
    
    func createPage(pageID: String) -> UIView? {
        guard let pageData = pageLookup[pageID], let pageClass = pageData.viewClass else {
            print("No page found for ID: \(pageID)")
            return nil
        }
        return pageClass.init(data: pageData.data ?? [:]) { }
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
