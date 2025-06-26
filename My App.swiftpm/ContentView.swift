import UIKit
import SwiftUI

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MapViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Model

struct Site {
    let id: Int
    let name: String
    let position: CGPoint
    let progress: Double
}

// MARK: - MapViewDelegate

protocol MapViewDelegate: AnyObject {
    func mapView(_ mapView: MapView, didSelect site: Site)
}

// MARK: - MapView

class MapView: UIView {
    private let sites: [Site]
    weak var delegate: MapViewDelegate?
    
    init(sites: [Site]) {
        self.sites = sites
        super.init(frame: .zero)
        backgroundColor = .white
        setupDots()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDots() {
        for site in sites {
            let dot = UIButton(type: .system)
            dot.backgroundColor = .systemBlue
            dot.layer.cornerRadius = 15
            dot.frame = CGRect(x: site.position.x, y: site.position.y, width: 30, height: 30)
            dot.tag = site.id
            dot.addTarget(self, action: #selector(dotTapped(_:)), for: .touchUpInside)
            addSubview(dot)
        }
    }
    
    @objc private func dotTapped(_ sender: UIButton) {
        guard let site = sites.first(where: { $0.id == sender.tag }) else { return }
        delegate?.mapView(self, didSelect: site)
    }
}

// MARK: - MapViewController

class MapViewController: UIViewController {
    
    private let sites: [Site] = [
        Site(id: 1, name: "Site A", position: CGPoint(x: 50, y: 100), progress: 0.3),
        Site(id: 2, name: "Site B", position: CGPoint(x: 120, y: 200), progress: 0.75),
        Site(id: 3, name: "Site C", position: CGPoint(x: 200, y: 50), progress: 0.0),
        Site(id: 4, name: "Site D", position: CGPoint(x: 300, y: 150), progress: 1.0),
        Site(id: 5, name: "Site E", position: CGPoint(x: 250, y: 250), progress: 0.6)
    ]
    
    private lazy var mapView = MapView(sites: sites)
    
    override func loadView() {
        view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
}

extension MapViewController: MapViewDelegate {
    func mapView(_ mapView: MapView, didSelect site: Site) {
        let siteVC = SiteViewController(site: site)
        siteVC.modalPresentationStyle = .fullScreen
        present(siteVC, animated: true)
    }
}

// MARK: - SiteViewController

class SiteViewController: UIViewController {
    
    private let site: Site
    
    init(site: Site) {
        self.site = site
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let backButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }
    
    private func setupUI() {
        // Back Button
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        // Title Label
        titleLabel.text = site.name
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // ScrollView and TextView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textColor = .black
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = loremIpsumText()
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
        
        // Constraints
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func loremIpsumText() -> String {
        // Generate ~3000 words of Lorem Ipsum
        let lorem = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. ...
        """
        // For brevity, I’ll repeat a base Lorem Ipsum paragraph to get close to 3000 words
        let baseParagraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        return String(repeating: baseParagraph, count: 3000 / 20) // approx 20 words per paragraph
    }
}
