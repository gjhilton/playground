import UIKit

class TornPaperMenuViewController: UIViewController {
    let titles: [String]
    let isMain: [Bool]
    var onSelect: ((Int, String) -> Void)?
    private var buttonViews: [TornPaperButtonView] = []
    private let stackView = UIStackView()
    
    init(titles: [String], isMain: [Bool]? = nil, onSelect: ((Int, String) -> Void)? = nil) {
        self.titles = titles
        self.isMain = isMain ?? Array(repeating: false, count: titles.count)
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Style.backgroundColor
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        for (i, title) in titles.enumerated() {
            let font = self.isMain[i] ? Style.menuButtonMainFont : Style.menuButtonFont
            let btn = TornPaperButtonView(title: title, font: font, isMain: self.isMain[i])
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(buttonTapped(_:)))
            btn.addGestureRecognizer(tap)
            btn.tag = i
            stackView.addArrangedSubview(btn)
            buttonViews.append(btn)
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 360),
                btn.heightAnchor.constraint(equalToConstant: 150)
            ])
        }
    }
    @objc private func buttonTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        onSelect?(tag, titles[tag])
    }
} 