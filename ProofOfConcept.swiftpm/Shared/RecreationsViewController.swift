//
//  RecreationsViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit

class RecreationsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUI()
        setupConstraints()
        loadContent()
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black
    }
    
    private func setupUI() {
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content label
        contentLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        contentLabel.textColor = .white
        contentLabel.textAlignment = .left
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentLabel)
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
            contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func loadContent() {
        contentLabel.text = """
        Other Dracula Recreations in Whitby
        
        Whitby has long been a source of inspiration for Gothic literature and Dracula adaptations. Here are some notable recreations and adaptations that have drawn from Bram Stoker's novel and the town's atmospheric setting:
        
        Film Adaptations:
        • Dracula (1958) - Christopher Lee's iconic portrayal
        • Bram Stoker's Dracula (1992) - Francis Ford Coppola's adaptation
        • Dracula Untold (2014) - Modern retelling
        
        Television:
        • Dracula (2020) - Netflix series
        • Penny Dreadful (2014-2016) - Gothic horror series
        
        Literature:
        • "Dracula's Guest" - Stoker's short story
        • Various Whitby-set Dracula sequels and prequels
        
        Theatre:
        • Annual Dracula performances at Whitby Abbey
        • Gothic theatre festivals
        
        The town's unique atmosphere, with its abbey ruins, narrow streets, and maritime history, continues to inspire new interpretations of the Dracula story, making Whitby a living museum of Gothic literature and a pilgrimage site for fans of the genre.
        """
    }
} 