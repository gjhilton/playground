import UIKit
import SwiftUI 

struct ContentView: UIViewControllerRepresentable {
    @State private var splashFinished = false
    
    func makeUIViewController(context: Context) -> UIViewController {
        if splashFinished {
            return UIViewController() // Empty or main content here
        } else {
            let splash = SplashPageView()
            splash.onFinish = {
                DispatchQueue.main.async {
                    splashFinished = true
                }
            }
            DispatchQueue.main.async {
                splash.run()
            }
            return splash
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
