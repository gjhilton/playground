import UIKit

class ExtrasMenuViewController: TornPaperMenuViewController {
    private let node: ExtrasNode
    var didSelectNode: ((ExtrasNode) -> Void)?
    init(node: ExtrasNode) {
        self.node = node
        let children = node.children ?? []
        let titles = children.map { $0.title }
        super.init(titles: titles, onSelect: { _, _ in })
        self.onSelect = { [weak self] index, _ in
            guard let self = self, index < children.count else { return }
            self.didSelectNode?(children[index])
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
} 