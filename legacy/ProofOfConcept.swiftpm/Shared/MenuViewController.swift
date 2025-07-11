//
//  MenuViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit
import CoreLocation

class MenuViewController: UIViewController {
    var onNavigate: ((String) -> Void)?
    private var buttonViews: [TornPaperButtonView] = []
    // Correct order: bottom to top in array, but laid out bottom to top
    private let buttonTitles = ["Help", "Extras", "Parlour", "Promenade"]
    private let buttonRotations: [CGFloat] = [-3.5, 2.5, -1.5, 3.5]
    private let isMain: [Bool] = [false, false, true, true]
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Style.backgroundColor
        for i in 0..<buttonTitles.count {
            let font = isMain[i] ? Style.menuButtonMainFont.withSize(Style.menuButtonMainFont.pointSize * 0.7) : Style.menuButtonFont.withSize(Style.menuButtonFont.pointSize * 0.7)
            let btn = TornPaperButtonView(title: buttonTitles[i], font: font, isMain: isMain[i])
            btn.transform = CGAffineTransform(rotationAngle: buttonRotations[i] * .pi / 180)
            btn.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(btn)
            buttonViews.append(btn)
            btn.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(buttonTapped(_:)))
            btn.addGestureRecognizer(tap)
            btn.tag = i
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let buttonWidth: CGFloat = 360
        let buttonHeight: CGFloat = 150
        let overlap: CGFloat = 60
        let buttonCount = buttonViews.count
        let clusterHeight = buttonHeight + CGFloat(buttonCount - 1) * (buttonHeight - overlap)
        let centerX = view.bounds.width / 2
        let startY = (view.bounds.height - clusterHeight) / 2
        // Lay out from bottom to top: last in array at top, first at bottom
        for (i, btn) in buttonViews.enumerated() {
            let y = startY + CGFloat(buttonCount - 1 - i) * (buttonHeight - overlap)
            btn.frame = CGRect(x: centerX - buttonWidth / 2, y: y, width: buttonWidth, height: buttonHeight)
        }
        for btn in buttonViews { view.bringSubviewToFront(btn) }
    }
    @objc private func buttonTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        switch tag {
        case 0: // Help
            onNavigate?("Help")
        case 1: // Extras
            onNavigate?("Extras")
        default:
            print("Tapped: \(buttonTitles[tag])")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MenuViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle location authorization changes
    }
} 