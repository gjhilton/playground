import UIKit

class ExtrasContentViewController: UIViewController {
    private let node: ExtrasNode
    private let scrollView = UIScrollView()
    private let contentLabel = UILabel()
    private let backButton = UIButton(type: .system)
    var onBack: (() -> Void)?
    private var resourceProvider: ResourceProvider = DefaultResourceProvider()
    
    init(node: ExtrasNode) {
        self.node = node
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUI()
        setupConstraints()
        loadContent()
    }
    
    private func setupView() {
        view.backgroundColor = .white
    }
    
    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        contentLabel.textColor = .black
        contentLabel.textAlignment = .left
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentLabel)
        backButton.setTitle("<", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        backButton.tintColor = .black
        backButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadContent() {
        guard let htmlFile = node.htmlFile else {
            contentLabel.text = "Content not found."
            return
        }
        let fileName = htmlFile.replacingOccurrences(of: ".html", with: "")
        guard let data = resourceProvider.data(forResource: fileName, withExtension: "html") else {
            contentLabel.text = "Content not found."
            return
        }
        do {
            let attributedString = try NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            let fullRange = NSRange(location: 0, length: attributedString.length)
            attributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
                if let font = value as? UIFont {
                    let largerFont = font.withSize(font.pointSize * 1.25)
                    attributedString.addAttribute(.font, value: largerFont, range: range)
                }
            }
            contentLabel.attributedText = attributedString
        } catch {
            contentLabel.text = "Failed to load content."
        }
    }
    
    @objc private func backTapped() {
        onBack?()
    }
} 