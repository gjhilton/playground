import SwiftUI
import UIKit

// Your original UIKit view controller
class PageCurlViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var pageController: UIPageViewController!
    var controllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        pageController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageController.dataSource = self
        pageController.delegate = self
        
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Create 5 view controllers with random background colors
        for _ in 1...5 {
            let vc = UIViewController()
            vc.view.backgroundColor = randomColor()
            controllers.append(vc)
        }
        
        pageController.setViewControllers([controllers[0]], direction: .forward, animated: false)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else {
            return nil
        }
        return controllers[index + 1]
    }
    
    func randomCGFloat() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
    
    func randomColor() -> UIColor {
        return UIColor(red: randomCGFloat(), green: randomCGFloat(), blue: randomCGFloat(), alpha: 1)
    }
}

// SwiftUI wrapper using UIViewControllerRepresentable
struct PageCurlView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PageCurlViewController {
        return PageCurlViewController()
    }
    
    func updateUIViewController(_ uiViewController: PageCurlViewController, context: Context) {
        // No need to update anything dynamically
    }
}

// Main SwiftUI entry point for the Playground
struct ContentView: View {
    var body: some View {
        PageCurlView()
            .edgesIgnoringSafeArea(.all)
    }
}
