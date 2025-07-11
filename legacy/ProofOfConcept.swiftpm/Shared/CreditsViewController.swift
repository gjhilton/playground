//
//  CreditsViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit

class CreditsViewController: UIViewController {
    
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
        CREDITS
        
        Dracumentary
        A Walking Tour of Whitby
        
        Development Team:
        • Lead Developer: [Your Name]
        • UI/UX Design: [Designer Name]
        • Content Research: [Researcher Name]
        
        Original Novel:
        • "Dracula" by Bram Stoker (1897)
        • Published by Archibald Constable and Company
        
        Historical Research:
        • Whitby Museum
        • Whitby Abbey
        • Local Historical Society
        
        Audio Narration:
        • Narrator: [Narrator Name]
        • Recording Studio: [Studio Name]
        
        Music:
        • Composer: [Composer Name]
        • Gothic and atmospheric compositions
        
        Photography:
        • Location Photography: [Photographer Name]
        • Historical Images: Various Sources
        
        Special Thanks:
        • The people of Whitby
        • Whitby Tourism Board
        • Bram Stoker Estate
        • All Dracula enthusiasts worldwide
        
        © 2025 Funeral Games
        All rights reserved.
        
        This app is a tribute to Bram Stoker's masterpiece and the beautiful town of Whitby that inspired it.
        """
    }
} 