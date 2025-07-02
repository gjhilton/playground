/*
 SplashPageView.swift
 
 Overview:
 This class manages a sequence of full-screen splash scenes (SplashSceneView subclasses) 
 displayed one after another with sliding transitions. It acts as a self-contained controller 
 responsible for presenting, transitioning, timing, and restarting splash screens, abstracting 
 away all animation and timing logic from its consumer.
 
 Functionality:
 - Manages an ordered array of SplashSceneView instances.
 - Shows each scene by sliding it in from the right.
 - After the scene's duration elapses, slides the current scene off to the left while simultaneously sliding the next scene in from the right.
 - The last scene also slides off to the left once its duration is over, signaling the end of the splash sequence.
 - Supports interruption handling: when the app resigns active or orientation changes, the entire sequence restarts from scratch.
 - Uses UIKit animations and timers to coordinate transitions.
 - Provides an onFinish closure callback to notify when the splash sequence completes.
 
 Key Properties:
 - scenes: Holds the splash scenes in order.
 - currentIndex: Tracks the index of the currently visible scene.
 - currentSceneView: Reference to the currently visible SplashSceneView instance.
 - timer: Schedules duration-based callbacks for transitioning scenes.
 - isTransitioning: Guards against concurrent animations or state conflicts.
 - onFinish: Closure callback invoked after all scenes have been shown and slid off.
 
 Lifecycle:
 1. viewDidLoad
 - Sets up scenes and background color.
 - Registers for interruption and orientation change notifications.
 2. run()
 - Entry point to start the splash sequence.
 - Initializes currentIndex and triggers first slide-in.
 3. slideInNextScene()
 - Advances currentIndex.
 - If index exceeds scenes count, slides off last view and calls onFinish.
 - Otherwise, slides new scene in from the right.
 - Sets timer for scene duration upon animation completion.
 4. transitionToNextScene()
 - Slides current scene off left and next scene in from right concurrently.
 - Updates currentIndex and currentSceneView.
 - Starts timer for new scene duration.
 5. restart()
 - Called on interruptions or orientation changes.
 - Invalidates timers, clears views, resets index.
 - Reinitializes scenes and restarts sequence.
 
 Design Decisions & Rationale:
 - UIKit over SwiftUI: The entire splash flow is implemented with UIKit views and animations for precise control over frame-based slide transitions, which are not trivial in SwiftUI.
 - Self-contained & Black-box: SplashPageView encapsulates all splash logic so the consumer (ContentView) only instantiates, calls run(), and listens for onFinish. This keeps integration clean and reduces coupling.
 - Timer-based duration control: Allows each splash scene to define its own visible duration.
 - Transition synchronization guarded with isTransitioning flag to avoid race conditions.
 - Full restart on interruption and rotation ensures visual consistency and resets state cleanly.
 - Slide transitions use ease-in-out curve and 2-second duration for smooth, natural animation.
 - Scenes themselves are simple UIView subclasses with a label and duration property, making them easily extendable.
 
 Context & Usage Notes:
 - The SplashPageView expects to be embedded in a UIViewController context (e.g., via UIViewControllerRepresentable in SwiftUI).
 - The consumer must call run() after the view is loaded and visible to start the splash sequence.
 - onFinish allows the consumer to remove the splash and proceed with the app UI.
 - Orientation changes and app interruptions automatically reset the splash sequence.
 - Timer and animation callbacks always update UI on main thread.
 - SplashSceneView subclasses can be extended to show any custom content and specify their own duration.
 - This design is optimized for simple splash flows with a small number of screens and predictable durations.
 
 Summary:
 SplashPageView is a robust, reusable UIKit-based splash screen sequencer designed for full control over splash screen display, timing, and transitions. It ensures smooth animations, clean lifecycle handling, and minimal external dependencies, allowing future customization or extension with minimal friction.
 */

import UIKit

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
