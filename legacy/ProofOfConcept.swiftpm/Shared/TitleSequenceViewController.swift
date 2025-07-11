//
//  TitleSequenceViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit
import QuartzCore

class TitleSequenceViewController: UIViewController {
    
    // MARK: - Properties
    var onComplete: (() -> Void)?
    private var currentSceneIndex = 0
    private var scenes: [UIView] = []
    private var isAnimating = false
    private var skipButton: UIButton!
    
    // MARK: - Scene Data
    private let sceneData = [
        ("THE GUIDE: SEAN BEAN", "guide"),
        ("MUSIC: ANNA VON HAUSSWOLFF", "music"),
        ("FUNERAL GAMES PRESENTS", "presents"),
        ("BRAM STOKER IN WHITBY", "whitby")
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        createScenes()
        setupSkipButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTitleSequence()
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .white
    }
    
    private func createScenes() {
        for (index, (title, identifier)) in sceneData.enumerated() {
            let sceneView = createSceneView(title: title, identifier: identifier)
            sceneView.isHidden = index != 0
            scenes.append(sceneView)
            view.addSubview(sceneView)
            
            // Set up constraints
            sceneView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sceneView.topAnchor.constraint(equalTo: view.topAnchor),
                sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    private func createSceneView(title: String, identifier: String) -> UIView {
        let sceneView = UIView()
        sceneView.backgroundColor = .white
        
        // Create title with two-size typography
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.spacing = 8
        titleStackView.alignment = .center
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let (smallText, largeText) = getTitleTexts(for: identifier)
        
        if identifier == "presents" {
            // Large label on top, small label below
            if let largeText = largeText {
                let largeLabel = UILabel()
                largeLabel.text = largeText
                largeLabel.textColor = .black
                largeLabel.font = UIFont(name: "LibreBaskerville-Bold", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
                largeLabel.textAlignment = .center
                largeLabel.numberOfLines = 0
                largeLabel.lineBreakMode = .byWordWrapping
                titleStackView.addArrangedSubview(largeLabel)
            }
            if let smallText = smallText {
                let smallLabel = UILabel()
                smallLabel.text = smallText
                smallLabel.textColor = .black
                smallLabel.font = UIFont(name: "LibreBaskerville-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
                smallLabel.textAlignment = .center
                smallLabel.numberOfLines = 0
                smallLabel.lineBreakMode = .byWordWrapping
                titleStackView.addArrangedSubview(smallLabel)
            }
        } else {
            // Default: small label on top, large label below
            if let smallText = smallText {
                let smallLabel = UILabel()
                smallLabel.text = smallText
                smallLabel.textColor = .black
                smallLabel.font = UIFont(name: "LibreBaskerville-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
                smallLabel.textAlignment = .center
                smallLabel.numberOfLines = 0
                smallLabel.lineBreakMode = .byWordWrapping
                titleStackView.addArrangedSubview(smallLabel)
            }
            if let largeText = largeText {
                let largeLabel = UILabel()
                largeLabel.text = largeText
                largeLabel.textColor = .black
                largeLabel.font = UIFont(name: "LibreBaskerville-Bold", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
                largeLabel.textAlignment = .center
                largeLabel.numberOfLines = 0
                largeLabel.lineBreakMode = .byWordWrapping
                titleStackView.addArrangedSubview(largeLabel)
            }
        }
        
        sceneView.addSubview(titleStackView)
        
        // Create decorative elements based on identifier
        let decorativeView = createDecorativeView(for: identifier)
        decorativeView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(decorativeView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            titleStackView.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            titleStackView.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor),
            titleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: sceneView.leadingAnchor, constant: 40),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: sceneView.trailingAnchor, constant: -40),
            
            decorativeView.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor),
            decorativeView.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 60),
            decorativeView.widthAnchor.constraint(equalToConstant: 200),
            decorativeView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        return sceneView
    }
    
    private func createDecorativeView(for identifier: String) -> UIView {
        let view = UIView()
        
        switch identifier {
        case "presents":
            // Create a simple line decoration
            let line = UIView()
            line.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
            line.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(line)
            
            NSLayoutConstraint.activate([
                line.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                line.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                line.widthAnchor.constraint(equalToConstant: 100),
                line.heightAnchor.constraint(equalToConstant: 2)
            ])
            
        case "whitby":
            // Create a gothic arch shape
            let archLayer = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 100))
            path.addLine(to: CGPoint(x: 50, y: 0))
            path.addLine(to: CGPoint(x: 150, y: 0))
            path.addLine(to: CGPoint(x: 200, y: 100))
            archLayer.path = path.cgPath
            archLayer.strokeColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
            archLayer.fillColor = UIColor.clear.cgColor
            archLayer.lineWidth = 3
            view.layer.addSublayer(archLayer)
            
        case "guide":
            // Create a microphone icon
            let micView = UIView()
            micView.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            micView.layer.cornerRadius = 25
            micView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(micView)
            
            NSLayoutConstraint.activate([
                micView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                micView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                micView.widthAnchor.constraint(equalToConstant: 50),
                micView.heightAnchor.constraint(equalToConstant: 50)
            ])
            
        case "music":
            // Create musical notes
            let noteView = UIView()
            noteView.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            noteView.layer.cornerRadius = 15
            noteView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(noteView)
            
            NSLayoutConstraint.activate([
                noteView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                noteView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                noteView.widthAnchor.constraint(equalToConstant: 30),
                noteView.heightAnchor.constraint(equalToConstant: 30)
            ])
            
        default:
            break
        }
        
        return view
    }
    
    private func getTitleTexts(for identifier: String) -> (smallText: String?, largeText: String?) {
        switch identifier {
        case "guide":
            return ("THE GUIDE:", "SEAN BEAN")
        case "music":
            return ("MUSIC:", "ANNA VON HAUSSWOLFF")
        case "presents":
            return ("PRESENTS", "FUNERAL GAMES")
        case "whitby":
            return ("BRAM STOKER'S", "WHITBY")
        default:
            return (nil, nil)
        }
    }
    
    private func setupSkipButton() {
        skipButton = UIButton(type: .system)
        skipButton.setTitle("SKIP", for: .normal)
        skipButton.setTitleColor(.black, for: .normal)
        skipButton.titleLabel?.font = UIFont(name: "LibreBaskerville-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        skipButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        skipButton.layer.cornerRadius = 20
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor.black.cgColor
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            skipButton.widthAnchor.constraint(equalToConstant: 80),
            skipButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Animation
    private func startTitleSequence() {
        animateToNextScene()
    }
    
    private func animateToNextScene() {
        guard currentSceneIndex < scenes.count && !isAnimating else {
            if currentSceneIndex >= scenes.count {
                completeTitleSequence()
            }
            return
        }
        
        isAnimating = true
        let currentScene = scenes[currentSceneIndex]
        
        // Show current scene
        currentScene.isHidden = false
        
        // Animate title stack view
        if let titleStackView = currentScene.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            UIView.animate(withDuration: 1.0, delay: 0.5, options: .curveEaseInOut) {
                titleStackView.alpha = 1.0
            }
        }
        
        // Animate decorative elements
        if let decorativeView = currentScene.subviews.last {
            decorativeView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 1.5, delay: 1.0, options: .curveEaseOut) {
                decorativeView.transform = .identity
            }
        }
        
        // Schedule next scene - 5 seconds total duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.transitionToNextScene()
        }
    }
    
    private func transitionToNextScene() {
        guard currentSceneIndex < scenes.count - 1 else {
            completeTitleSequence()
            return
        }
        
        let currentScene = scenes[currentSceneIndex]
        _ = scenes[currentSceneIndex + 1] // Unused but kept for clarity
        
        // Fade out current scene
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            currentScene.alpha = 0
        } completion: { _ in
            currentScene.isHidden = true
            currentScene.alpha = 1
            
            // Move to next scene
            self.currentSceneIndex += 1
            self.isAnimating = false
            self.animateToNextScene()
        }
    }
    
    private func completeTitleSequence() {
        // Notify completion so the app delegate can handle the transition
        onComplete?()
    }
    
    // MARK: - Actions
    @objc private func skipButtonTapped() {
        completeTitleSequence()
    }
} 