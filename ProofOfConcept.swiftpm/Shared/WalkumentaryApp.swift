//
//  DracumentaryApp.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

// import UIKit
// import CoreText

// class AppDelegate: UIResponder, UIApplicationDelegate {
//     var window: UIWindow?
//     
//     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//         window = UIWindow(frame: UIScreen.main.bounds)
//         let titleVC = TitleSequenceViewController()
//         titleVC.onComplete = { [weak self] in
//             guard let self = self else { return }
//             let horizontalStackVC = HorizontalStackContainerViewController()
//             let menuVC = MenuViewController()
//             // Set up navigation from menu
//             menuVC.onNavigate = { [weak horizontalStackVC] destination in
//                 switch destination {
//                 case "Help":
//                     let helpVC = HelpViewController()
//                     horizontalStackVC?.pushFullScreen(helpVC, animated: true)
//                 case "Extras":
//                     let extrasVC = ExtrasViewController()
//                     horizontalStackVC?.pushFullScreen(extrasVC, animated: true)
//                 default:
//                     break
//                 }
//             }
//             // Push menu as root
//             horizontalStackVC.pushFullScreen(menuVC, animated: false, injectBack: false)
//             horizontalStackVC.view.frame = CGRect(x: self.window!.bounds.width, y: 0, width: self.window!.bounds.width, height: self.window!.bounds.height)
//             self.window?.addSubview(horizontalStackVC.view)
//             self.window?.bringSubviewToFront(horizontalStackVC.view)
//             UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
//                 horizontalStackVC.view.frame = self.window!.bounds
//                 titleVC.view.frame = CGRect(x: -self.window!.bounds.width, y: 0, width: self.window!.bounds.width, height: self.window!.bounds.height)
//             }, completion: { _ in
//                 self.window?.rootViewController = horizontalStackVC
//             })
//         }
//         window?.rootViewController = titleVC
//         window?.makeKeyAndVisible()
//         return true
//     }
//     
//     private func registerCustomFonts() {
//         let fontNames = [
//             "LibreBaskerville-Regular",
//             "LibreBaskerville-Bold", 
//             "LibreBaskerville-Italic"
//         ]
//         
//         for fontName in fontNames {
//             if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") {
//                 if let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
//                    let font = CGFont(fontDataProvider) {
//                     var error: Unmanaged<CFError>?
//                     if CTFontManagerRegisterGraphicsFont(font, &error) {
//                         print("Successfully registered font: \(fontName)")
//                     } else {
//                         print("Failed to register font: \(fontName), error: \(String(describing: error))")
//                     }
//                 }
//             } else {
//                 print("Could not find font file: \(fontName).otf")
//             }
//         }
//     }
// }
