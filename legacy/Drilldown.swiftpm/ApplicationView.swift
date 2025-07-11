import UIKit

final class ApplicationView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var views: [UIView] = []
    private var initialViewClass: TitlePageViewProtocol.Type
    private var rootPageData: PageData?
    
    init(initialViewClass: TitlePageViewProtocol.Type, pageData: PageData?) {
        self.initialViewClass = initialViewClass
        self.rootPageData = pageData
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
        let titlePageView = initialViewClass.init(onReady: { [weak self] in
            self?.addRootPage()
        })
        appendPage(titlePageView)
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
        
