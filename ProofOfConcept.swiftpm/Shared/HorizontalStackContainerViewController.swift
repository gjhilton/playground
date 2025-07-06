import UIKit

protocol HorizontalStackNavigable: AnyObject {
    /// Called by the container to inject a back button if needed
    func setBackButtonAction(_ action: @escaping () -> Void)
}

class HorizontalStackContainerViewController: UIViewController {
    private var viewControllerStack: [UIViewController] = []
    private var isTransitioning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeBack(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)
    }
    
    @objc private func handleSwipeBack(_ gesture: UISwipeGestureRecognizer) {
        pop(animated: true)
    }
    
    // MARK: - Public API
    func pushFullScreen(_ vc: UIViewController, animated: Bool = true, injectBack: Bool = true) {
        guard !isTransitioning else { return }
        let width = view.bounds.width
        let height = view.bounds.height
        addChild(vc)
        vc.view.frame = CGRect(x: animated ? width : 0, y: 0, width: width, height: height)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        if injectBack, viewControllerStack.count > 0, let nav = vc as? HorizontalStackNavigable {
            nav.setBackButtonAction { [weak self] in self?.pop(animated: true) }
        }
        let previousVC = viewControllerStack.last
        viewControllerStack.append(vc)
        guard animated, let fromVC = previousVC else { return }
        isTransitioning = true
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            fromVC.view.frame = CGRect(x: -width, y: 0, width: width, height: height)
            vc.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }, completion: { _ in
            fromVC.view.removeFromSuperview()
            self.isTransitioning = false
        })
    }
    
    func pop(animated: Bool = true) {
        guard viewControllerStack.count > 1, !isTransitioning else { return }
        let width = view.bounds.width
        let height = view.bounds.height
        let fromVC = viewControllerStack.removeLast()
        let toVC = viewControllerStack.last!
        addChild(toVC)
        toVC.view.frame = CGRect(x: -width, y: 0, width: width, height: height)
        view.addSubview(toVC.view)
        toVC.didMove(toParent: self)
        isTransitioning = true
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            fromVC.view.frame = CGRect(x: width, y: 0, width: width, height: height)
            toVC.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }, completion: { _ in
            fromVC.view.removeFromSuperview()
            fromVC.removeFromParent()
            self.isTransitioning = false
        })
    }
    
    func popToRoot(animated: Bool = true) {
        while viewControllerStack.count > 1 {
            pop(animated: animated)
        }
    }
    
    func replaceStack(with vcs: [UIViewController], animated: Bool = false) {
        // Remove all current VCs
        for vc in viewControllerStack {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        viewControllerStack.removeAll()
        // Add new stack
        for (i, vc) in vcs.enumerated() {
            addChild(vc)
            vc.view.frame = view.bounds
            view.addSubview(vc.view)
            vc.didMove(toParent: self)
            if i < vcs.count - 1, let nav = vc as? HorizontalStackNavigable {
                nav.setBackButtonAction { [weak self] in self?.pop(animated: true) }
            }
            viewControllerStack.append(vc)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the top VC fills the view
        if let topVC = viewControllerStack.last {
            topVC.view.frame = view.bounds
        }
    }
}
