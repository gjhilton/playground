import UIKit

struct Style {
    static let backgroundColor: UIColor = .white
    static let textColor: UIColor = .black
    static let accentColor: UIColor = UIColor(red: 0.7, green: 0, blue: 0, alpha: 1) // Blood red
    static let tornEdgeAmplitude: CGFloat = 8
    static let tornEdgeVertices: Int = 30
    static let tornEdgeHorizontalJitter: CGFloat = 2
    static let tornEdgeVerticalJitter: CGFloat = 3
    static let menuButtonFont: UIFont = UIFont(name: "LibreBaskerville-Regular", size: 28) ?? UIFont.systemFont(ofSize: 28)
    static let menuButtonMainFont: UIFont = UIFont(name: "LibreBaskerville-Regular", size: 38) ?? UIFont.systemFont(ofSize: 38)
    static let menuButtonShadow: CGSize = CGSize(width: 0, height: 2)
    static let menuButtonShadowOpacity: Float = 0.18
    static let menuButtonShadowRadius: CGFloat = 6
    // Add more as needed
} 