//
//  LocationContentViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit
import AVFoundation

class LocationContentViewController: UIViewController {
    
    // MARK: - Properties
    private let location: TourLocation
    private var currentFragmentIndex = 0
    private var audioPlayer: AVAudioPlayer?
    private var isAudioEnabled = true
    private var autoPlayTimer: Timer?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let audioToggleButton = UIButton()
    private let progressView = UIProgressView()
    private let fragmentViews: [UIView] = []
    
    // MARK: - Initialization
    init(location: TourLocation) {
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUI()
        setupConstraints()
        loadContent()
        setupAudio()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutoPlay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoPlay()
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
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Audio toggle button
        audioToggleButton.setTitle("🔊", for: .normal)
        audioToggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        audioToggleButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        audioToggleButton.layer.cornerRadius = 25
        audioToggleButton.addTarget(self, action: #selector(audioToggleButtonTapped), for: .touchUpInside)
        audioToggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(audioToggleButton)
        
        // Progress view
        progressView.progressTintColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
        progressView.trackTintColor = UIColor.gray.withAlphaComponent(0.3)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -20),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            audioToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            audioToggleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            audioToggleButton.widthAnchor.constraint(equalToConstant: 50),
            audioToggleButton.heightAnchor.constraint(equalToConstant: 50),
            
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    // MARK: - Content Loading
    private func loadContent() {
        // Clear existing content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add location title
        let titleLabel = UILabel()
        titleLabel.text = location.name
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(titleLabel)
        
        // Add content fragments
        for (index, fragment) in location.contentFragments.enumerated() {
            let fragmentView = createFragmentView(fragment: fragment, index: index)
            contentStackView.addArrangedSubview(fragmentView)
        }
        
        // Update progress
        updateProgress()
    }
    
    private func createFragmentView(fragment: ContentFragment, index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0) // Parchment
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fragment type indicator
        let typeLabel = UILabel()
        typeLabel.text = getTypeIndicator(for: fragment.type)
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        typeLabel.textColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(typeLabel)
        
        // Fragment text
        let textLabel = UILabel()
        textLabel.text = fragment.text
        textLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textLabel.textColor = .black
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            typeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            typeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            typeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            textLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 10),
            textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            textLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15)
        ])
        
        return containerView
    }
    
    private func getTypeIndicator(for type: ContentFragment.ContentType) -> String {
        switch type {
        case .narration:
            return "📖 NARRATION"
        case .bookExtract:
            return "📚 BOOK EXTRACT"
        case .image:
            return "🖼️ IMAGE"
        case .historicalNote:
            return "📜 HISTORICAL NOTE"
        }
    }
    
    // MARK: - Audio Setup
    private func setupAudio() {
        // For now, we'll simulate audio with timers
        // In a real implementation, you would load actual audio files
        print("Audio setup completed for location: \(location.name)")
    }
    
    // MARK: - Auto Play
    private func startAutoPlay() {
        guard isAudioEnabled else { return }
        
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.advanceToNextFragment()
        }
    }
    
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    private func advanceToNextFragment() {
        guard currentFragmentIndex < location.contentFragments.count - 1 else {
            // Reached the end
            stopAutoPlay()
            return
        }
        
        currentFragmentIndex += 1
        highlightCurrentFragment()
        updateProgress()
        
        // Scroll to current fragment
        if currentFragmentIndex + 1 < contentStackView.arrangedSubviews.count {
            let fragmentView = contentStackView.arrangedSubviews[currentFragmentIndex + 1] // +1 for title
            scrollView.scrollRectToVisible(fragmentView.frame, animated: true)
        }
    }
    
    private func highlightCurrentFragment() {
        // Reset all fragments
        for (index, subview) in contentStackView.arrangedSubviews.enumerated() {
            if index > 0 { // Skip title
                subview.alpha = 0.7
                subview.transform = .identity
            }
        }
        
        // Highlight current fragment
        if currentFragmentIndex + 1 < contentStackView.arrangedSubviews.count {
            let currentFragmentView = contentStackView.arrangedSubviews[currentFragmentIndex + 1]
            UIView.animate(withDuration: 0.3) {
                currentFragmentView.alpha = 1.0
                currentFragmentView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            }
        }
    }
    
    private func updateProgress() {
        let progress = Float(currentFragmentIndex) / Float(max(1, location.contentFragments.count - 1))
        progressView.setProgress(progress, animated: true)
        
        // Update app state
        AppState.shared.updateLocationProgress(location.id, progress: Double(progress))
    }
    
    // MARK: - Actions
    @objc private func audioToggleButtonTapped() {
        isAudioEnabled.toggle()
        
        if isAudioEnabled {
            audioToggleButton.setTitle("🔊", for: .normal)
            startAutoPlay()
        } else {
            audioToggleButton.setTitle("🔇", for: .normal)
            stopAutoPlay()
        }
    }
} 