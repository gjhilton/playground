import SwiftUI
import UIKit

struct HelpViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HelpViewController {
        return HelpViewController()
    }
    func updateUIViewController(_ uiViewController: HelpViewController, context: Context) {}
} 