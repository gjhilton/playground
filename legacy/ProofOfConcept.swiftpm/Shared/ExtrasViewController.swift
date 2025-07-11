import UIKit

class ExtrasViewController: TornPaperMenuViewController {
    var onNavigate: ((String) -> Void)?
    init() {
        let titles = ["The Novel", "Other Recreations in Whitby", "Credits"]
        super.init(titles: titles, onSelect: { _, _ in })
        self.onSelect = { [weak self] index, _ in
            switch index {
            case 0: self?.onNavigate?("Novel")
            case 1: self?.onNavigate?("Recreations")
            case 2: self?.onNavigate?("Credits")
            default: break
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
} 