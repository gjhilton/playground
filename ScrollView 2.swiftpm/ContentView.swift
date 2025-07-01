import SwiftUI
import UIKit

// ApplicationView manages a sequence of pages
final class ApplicationView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var initialViewClass: TitleScreenViewProtocol.Type
    
    // Initializer for ApplicationView, accepts the initialViewClass (which is like TitleScreenView)
    init(initialViewClass: TitleScreenViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        super.init(frame: .zero)
        configure()
        layoutUI()
        addTitlePage()  // Renamed this method to addTitlePage
        self.backgroundColor = .white  // Set overall background to white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configuring the scrollView and stackView
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
    
    // Layout constraints for the scrollView and stackView
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
    
    // Adds the first page (Title page)
    private func addTitlePage() {
        let titleScreenView = initialViewClass.init(onReady: { [weak self] in
            self?.addPage(pageGuid: "secondPage")  // Pass pageGuid for the second page (green rectangle)
            self?.scrollToPage(index: 1)
        })
        
        addPage(view: titleScreenView, pageGuid: "firstPage")  // Add first page with its unique GUID
    }
    
    // Adds a new page dynamically and accepts a pageGuid argument
    private func addPage(view: UIView? = nil, color: UIColor? = nil, pageGuid: String) {
        let pageView = view ?? UIView()
        pageView.backgroundColor = color ?? .white  // Set the default page background to white
        
        // Optionally use the pageGuid for tracking purposes (you can store it in an array, dictionary, etc.)
        print("Adding page with GUID: \(pageGuid)") // For now, we're just printing the page GUID
        
        stackView.addArrangedSubview(pageView)
        views.append(pageView)
        pageView.translatesAutoresizingMaskIntoConstraints = false
        pageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
    }
    
    // Scroll to the desired page index
    private func scrollToPage(index: Int) {
        let offset = CGFloat(index) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }
}

// SwiftUI wrapper for ApplicationView
struct ApplicationViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ApplicationView {
        let appView = ApplicationView(initialViewClass: TitleScreenView.self)
        return appView
    }
    
    func updateUIView(_ uiView: ApplicationView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        ApplicationViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
