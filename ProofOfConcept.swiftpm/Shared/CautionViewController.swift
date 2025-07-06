//
//  CautionViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit

class CautionViewController: UIViewController {
    var onNavigate: ((UIViewController) -> Void)?
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let continueButton = UIButton()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Container view
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0) // Parchment
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).cgColor // Blood red
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title label
        titleLabel.text = "⚠️ CAUTION"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message label
        messageLabel.text = "Please take care when walking in public spaces. Be aware of your surroundings and stay safe while enjoying your tour of Whitby."
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .black
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Continue button
        continueButton.setTitle("I Understand - Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
        continueButton.layer.cornerRadius = 8
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(continueButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            continueButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func continueButtonTapped() {
        dismiss(animated: true) {
            let tourMapVC = TourMapViewController()
            self.onNavigate?(tourMapVC)
        }
    }
} 