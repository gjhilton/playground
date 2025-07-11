import UIKit
//
//  ChaptersViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

class ChaptersViewController: TornPaperMenuViewController {
    private let chapters = TourData.shared.chapters
    var didSelectChapter: ((Int) -> Void)?
    init() {
        let titles = chapters.map { $0.title }
        super.init(titles: titles, onSelect: { _, _ in })
        self.onSelect = { [weak self] index, _ in
            self?.didSelectChapter?(index)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
} 