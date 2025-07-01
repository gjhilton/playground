import SwiftUI
import UIKit

struct PageData {
    let viewClass: String?
    let data: [String: Any]?
    let childPages: [PageData]?
    let label: String?
}

final class ApplicationView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var initialViewClass: TitleScreenViewProtocol.Type
    
    let pageLookup: [String: PageData] = [
        "0000001": PageData(
            viewClass: "PlaceholderPageView",
            data: ["title": "Placeholder page"],
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
            guard let self = self else { return }
            if let secondPageView = self.createPage(pageGuid: "0000001") {
                self.appendPage(secondPageView)
                self.scrollToPage(index: 1)
            }
        })
        appendPage(titleScreenView)
    }
    
    // Create a UIView page for a given pageGuid
    func createPage(pageGuid: String) -> UIView? {
        guard let pageData = pageLookup[pageGuid] else {
            print("No page found for GUID: \(pageGuid)")
            return nil
        }
        
        // For now, only support "PlaceholderPageView" as a simple UIView with green background and a label
        if pageData.viewClass == "PlaceholderPageView" {
            let view = UIView()
            view.backgroundColor = .green
            
            if let title = pageData.data?["title"] as? String {
                let label = UILabel()
                label.text = title
                label.textColor = .white
                label.font = .boldSystemFont(ofSize: 32)
                label.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                ])
            }
            
            return view
        }
        
        // If viewClass is unknown, return a plain white UIView
        return UIView()
    }
    
    // Append a UIView page to the scrollView
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

// SwiftUI wrapper for ApplicationView
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
