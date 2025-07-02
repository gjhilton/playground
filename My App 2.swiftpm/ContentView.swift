import UIKit

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

protocol SplashPageViewDelegate: AnyObject {
    func splashDidFinish()
}

class SplashPageView: UIViewController {
    private var scenes: [SplashSceneView] = []
    private var currentIndex = -1
    private var currentSceneView: SplashSceneView?
    private var nextSceneView: SplashSceneView?
    private var timer: Timer?
    private var isTransitioning = false
    private var hasStarted = false
    
    private let replayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Replay", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    weak var delegate: SplashPageViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupReplayButton()
        setupScenes()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruptionEnded), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasStarted {
            hasStarted = true
            startSequence()
        }
    }
    
    private func setupReplayButton() {
        view.addSubview(replayButton)
        NSLayoutConstraint.activate([
            replayButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 100),
            replayButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        replayButton.addTarget(self, action: #selector(restartSequence), for: .touchUpInside)
    }
    
    private func setupScenes() {
        scenes = [SplashScenePresents(), SplashSceneTitle()]
        currentIndex = -1
    }
    
    private func startSequence() {
        currentSceneView?.removeFromSuperview()
        nextSceneView?.removeFromSuperview()
        currentSceneView = nil
        nextSceneView = nil
        currentIndex = -1
        slideInNextScene()
    }
    
    private func slideInNextScene() {
        guard !isTransitioning else { return }
        
        currentIndex += 1
        guard currentIndex < scenes.count else {
            return
        }
        
        let scene = scenes[currentIndex]
        scene.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        view.addSubview(scene)
        view.bringSubviewToFront(replayButton)
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
            UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
                self.currentSceneView?.frame = self.view.bounds.offsetBy(dx: -self.view.bounds.width, dy: 0)
            }, completion: { _ in
                self.currentSceneView?.removeFromSuperview()
                self.currentSceneView = nil
            })
            return
        }
        
        let currentView = currentSceneView!
        let nextView = scenes[nextIndex]
        nextView.frame = view.bounds.offsetBy(dx: view.bounds.width, dy: 0)
        view.addSubview(nextView)
        view.bringSubviewToFront(replayButton)
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
        restartSequence()
    }
    
    @objc private func handleOrientationChange() {
        restartSequence()
    }
    
    @objc private func restartSequence() {
        timer?.invalidate()
        currentSceneView?.removeFromSuperview()
        nextSceneView?.removeFromSuperview()
        currentSceneView = nil
        nextSceneView = nil
        hasStarted = false
        setupScenes()
        if isViewLoaded && view.window != nil {
            startSequence()
        }
    }
}

import SwiftUI

struct ContentView: UIViewControllerRepresentable {
    @State private var showSplash = true
    
    func makeUIViewController(context: Context) -> UIViewController {
        if showSplash {
            let splash = SplashPageView()
            splash.delegate = context.coordinator
            return splash
        } else {
            return UIViewController()
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, SplashPageViewDelegate {
        var parent: ContentView
        
        init(parent: ContentView) {
            self.parent = parent
        }
        
        func splashDidFinish() {
            DispatchQueue.main.async {
                self.parent.showSplash = false
            }
        }
    }
}
