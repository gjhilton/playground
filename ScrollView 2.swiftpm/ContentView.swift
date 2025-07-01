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
        addInitialView()
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
    
    // Adds the first view (initial page)
    private func addInitialView() {
        let titleScreenView = initialViewClass.init(onReady: { [weak self] in
            self?.addSecondPage()
            self?.scrollToPage(index: 1)
        })
        
        addView(titleScreenView)
    }
    
    // Adds a second page, which will simply be a green rectangle for now
    private func addSecondPage() {
        let secondPageView = UIView()
        secondPageView.backgroundColor = .green
        addView(secondPageView)
    }
    
    // Adds a view to the stack
    private func addView(_ view: UIView) {
        stackView.addArrangedSubview(view)
        views.append(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
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
