import UIKit
import SwiftUI

class SplashSceneView: UIView {
    var duration: TimeInterval { 0 }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplashScenePresents: SplashSceneView {
    override var duration: TimeInterval { 10 }
    
    override init() {
        super.init()
        let label = UILabel()
        label.text = "Presents"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplashSceneTitle: SplashSceneView {
    override var duration: TimeInterval { 4 }
    
    override init() {
        super.init()
        let label = UILabel()
        label.text = "Title Screen"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplashPageView: UIViewController {
    private var scenes: [SplashSceneView] = []
    private var currentIndex = -1
    private var currentSceneView: SplashSceneView?
    private var timer: Timer?
    private var isTransitioning = false
    
    /// Called when splash sequence finishes (all scenes shown and slid off)
    var onFinish: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScenes()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruptionEnded), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func setupScenes() {
        scenes = [SplashScenePresents(), SplashSceneTitle()]
        currentIndex = -1
        currentSceneView?.removeFromSuperview()
        currentSceneView = nil
    }
    
    func run() {
        guard isViewLoaded && view.window != nil else { return }
        currentIndex = -1
        slideInNextScene()
    }
    
    private func slideInNextScene() {
        guard !isTransitioning else { return }
        currentIndex += 1
        
        if currentIndex >= scenes.count {
            guard let lastView = currentSceneView else {
                onFinish?()
                return
            }
            isTransitioning = true
            UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
                lastView.frame = self.view.bounds.offsetBy(dx: -self.view.bounds.width, dy: 0)
            }, completion: { _ in
                lastView.removeFromSuperview()
                self.currentSceneView = nil
                self.isTransitioning = false
                self.onFinish?()
            })
            return
        }
        
        let scene = scenes[currentIndex]
        scene.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        view.addSubview(scene)
        isTransitioning = true
        
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            scene.frame = self.view.bounds
        }, completion: { _ in
            self.currentSceneView = scene
            self.isTransitioning = false
            self.timer = Timer.scheduledTimer(withTimeInterval: scene.duration, repeats: false) { _ in
                self.transitionToNextScene()
            }
        })
    }
    
    private func transitionToNextScene() {
        guard !isTransitioning else { return }
        
        let nextIndex = currentIndex + 1
        if nextIndex >= scenes.count {
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
        
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            currentView.frame = currentView.frame.offsetBy(dx: -self.view.bounds.width, dy: 0)
            nextView.frame = self.view.bounds
        }, completion: { _ in
            currentView.removeFromSuperview()
            self.currentSceneView = nextView
            self.currentIndex = nextIndex
            self.isTransitioning = false
            self.timer = Timer.scheduledTimer(withTimeInterval: nextView.duration, repeats: false) { _ in
                self.transitionToNextScene()
            }
        })
    }
    
    @objc private func handleInterruption() {
        timer?.invalidate()
    }
    
    @objc private func handleInterruptionEnded() {
        restart()
    }
    
    @objc private func handleOrientationChange() {
        restart()
    }
    
    private func restart() {
        timer?.invalidate()
        currentSceneView?.removeFromSuperview()
        currentSceneView = nil
        currentIndex = -1
        setupScenes()
        if isViewLoaded && view.window != nil {
            run()
        }
    }
}

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
