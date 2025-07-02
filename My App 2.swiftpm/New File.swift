import UIKit

public class SplashPageView: UIViewController {
    private let scenes: [SplashSceneView] = [SplashScenePresents(), SplashSceneTitle()]
    private var currentIndex = -1
    private var currentSceneView: SplashSceneView?
    private var isTransitioning = false
    
    private var delayTask: Task<Void, Never>?
    
    /// Called when splash sequence finishes (all scenes shown and slid off)
    public var onFinish: (() -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruptionEnded), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        delayTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    public func run() {
        guard isViewLoaded, view.window != nil else { return }
        currentIndex = -1
        currentSceneView?.removeFromSuperview()
        currentSceneView = nil
        slideInNextScene()
    }
    
    private func slideInNextScene() {
        guard !isTransitioning else { return }
        
        currentIndex += 1
        guard currentIndex < scenes.count else {
            guard let lastView = currentSceneView else {
                onFinish?()
                return
            }
            isTransitioning = true
            animateSlideOutLast(scene: lastView) { [weak self] in
                lastView.removeFromSuperview()
                self?.currentSceneView = nil
                self?.isTransitioning = false
                self?.onFinish?()
            }
            return
        }
        
        let scene = scenes[currentIndex]
        scene.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        view.addSubview(scene)
        isTransitioning = true
        
        animateSlideIn(scene: scene) { [weak self] in
            guard let self = self else { return }
            self.currentSceneView = scene
            self.isTransitioning = false
            self.scheduleDelay(for: scene.duration)
        }
    }
    
    private func transitionToNextScene() {
        guard !isTransitioning else { return }
        
        let nextIndex = currentIndex + 1
        guard nextIndex < scenes.count else {
            slideInNextScene()
            return
        }
        
        guard let currentView = currentSceneView else {
            slideInNextScene()
            return
        }
        
        let nextView = scenes[nextIndex]
        nextView.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        view.addSubview(nextView)
        isTransitioning = true
        
        animateSlideOut(currentScene: currentView, nextScene: nextView) { [weak self] in
            currentView.removeFromSuperview()
            guard let self = self else { return }
            self.currentSceneView = nextView
            self.currentIndex = nextIndex
            self.isTransitioning = false
            self.scheduleDelay(for: nextView.duration)
        }
    }
    
    // MARK: - Async Delay
    
    private func scheduleDelay(for duration: TimeInterval) {
        delayTask?.cancel()
        delayTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                self.transitionToNextScene()
            }
        }
    }
    
    // MARK: - Animation Helpers
    
    private func animateSlideIn(scene: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            scene.frame = self.view.bounds
        }, completion: { _ in completion() })
    }
    
    private func animateSlideOut(currentScene: UIView, nextScene: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            currentScene.frame = currentScene.frame.offsetBy(dx: -self.view.bounds.width, dy: 0)
            nextScene.frame = self.view.bounds
        }, completion: { _ in completion() })
    }
    
    private func animateSlideOutLast(scene: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            scene.frame = self.view.bounds.offsetBy(dx: -self.view.bounds.width, dy: 0)
        }, completion: { _ in completion() })
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleInterruption() {
        delayTask?.cancel()
    }
    
    @objc private func handleInterruptionEnded() {
        restart()
    }
    
    @objc private func handleOrientationChange() {
        restart()
    }
    
    private func restart() {
        delayTask?.cancel()
        currentSceneView?.removeFromSuperview()
        currentSceneView = nil
        currentIndex = -1
        slideInNextScene()
    }
}
