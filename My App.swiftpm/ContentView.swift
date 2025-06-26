import SwiftUI
import UIKit

// MARK: - Data Models

struct Waypoint {
    let id: Int
    let title: String
    let content: String
}

struct WaypointState: Codable {
    var progress: Float  // 0.0 ... 1.0
    var isLocked: Bool
}

// MARK: - ViewModel

class MapViewModel {
    private(set) var waypoints: [Waypoint]
    private(set) var states: [WaypointState]
    
    init() {
        let lorem = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. \
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. \
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        let longText = Array(repeating: lorem, count: 80).joined(separator: "\n\n")
        
        waypoints = []
        states = []
        for i in 0..<10 {
            waypoints.append(Waypoint(id: i, title: "Waypoint \(i + 1)", content: longText))
            states.append(WaypointState(progress: 0, isLocked: i != 0)) // Only first unlocked
        }
    }
    
    func updateProgress(for waypointId: Int, progress: Float) {
        guard states.indices.contains(waypointId) else { return }
        if states[waypointId].isLocked { return }
        
        let clampedProgress = max(0, min(progress, 1))
        let previousProgress = states[waypointId].progress
        states[waypointId].progress = clampedProgress
        
        if previousProgress < 1 && clampedProgress >= 1 {
            unlockNext(after: waypointId)
        }
    }
    
    private func unlockNext(after index: Int) {
        let nextIndex = index + 1
        guard states.indices.contains(nextIndex) else { return }
        if states[nextIndex].isLocked {
            states[nextIndex].isLocked = false
        }
    }
}

// MARK: - Waypoint View (larger dot + circular progress)

class WaypointView: UIView {
    private let dotDiameter: CGFloat = 60  // doubled size
    private let circleLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let iconLayer = CATextLayer()
    
    var waypoint: Waypoint {
        didSet { updateAppearance() }
    }
    var state: WaypointState {
        didSet { updateAppearance() }
    }
    
    var tapHandler: (() -> Void)?
    
    init(waypoint: Waypoint, state: WaypointState) {
        self.waypoint = waypoint
        self.state = state
        let frame = CGRect(origin: .zero, size: CGSize(width: dotDiameter, height: dotDiameter))
        super.init(frame: frame)
        setupLayers()
        updateAppearance()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (dotDiameter - 12) / 2  // more inset for stroke
        
        // Background circle
        circleLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true).cgPath
        circleLayer.fillColor = UIColor.red.cgColor
        layer.addSublayer(circleLayer)
        
        // Progress ring
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + CGFloat.pi * 2
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 6  // thicker ring
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        // Icon layer (lock or checkmark)
        iconLayer.alignmentMode = .center
        iconLayer.contentsScale = UIScreen.main.scale
        iconLayer.fontSize = 36  // bigger icon
        iconLayer.frame = bounds
        iconLayer.foregroundColor = UIColor.black.cgColor
        layer.addSublayer(iconLayer)
    }
    
    private func updateAppearance() {
        if state.isLocked {
            circleLayer.fillColor = UIColor.gray.cgColor
            progressLayer.strokeEnd = 0
            iconLayer.string = "🔒"
        } else if state.progress >= 1.0 {
            circleLayer.fillColor = UIColor.black.cgColor
            progressLayer.strokeEnd = 1.0
            iconLayer.string = "✔︎"
        } else {
            circleLayer.fillColor = UIColor.red.cgColor
            progressLayer.strokeEnd = CGFloat(state.progress)
            iconLayer.string = nil
        }
    }
    
    @objc private func tapped() {
        if !state.isLocked {
            tapHandler?()
        }
    }
}

// MARK: - ContentViewController

class ContentViewController: UIViewController, UIScrollViewDelegate {
    private var viewModel = MapViewModel()
    private var waypointViews: [WaypointView] = []
    private var contentViewContainer: UIView?
    
    private var currentWaypointIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        layoutMap()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutMap()
    }
    
    private func layoutMap() {
        waypointViews.forEach { $0.removeFromSuperview() }
        waypointViews.removeAll()
        
        let spacing: CGFloat = 110 // spacing for bigger dots
        let startX: CGFloat = 60
        let centerY = view.bounds.midY
        
        for i in 0..<viewModel.waypoints.count {
            let wp = viewModel.waypoints[i]
            let state = viewModel.states[i]
            let wpView = WaypointView(waypoint: wp, state: state)
            wpView.center = CGPoint(x: startX + CGFloat(i) * spacing, y: centerY)
            wpView.tapHandler = { [weak self] in
                self?.showContent(forIndex: i)
            }
            view.addSubview(wpView)
            waypointViews.append(wpView)
        }
    }
    
    private func showContent(forIndex index: Int) {
        currentWaypointIndex = index
        
        contentViewContainer?.removeFromSuperview()
        
        let containerWidth: CGFloat = 320
        let containerHeight: CGFloat = view.bounds.height * 0.8
        let containerX = (view.bounds.width - containerWidth) / 2
        let containerY = (view.bounds.height - containerHeight) / 2
        
        let container = UIView(frame: CGRect(x: containerX, y: containerY, width: containerWidth, height: containerHeight))
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 6
        view.addSubview(container)
        contentViewContainer = container
        
        // ScrollView with delegate to track scrolling
        let scrollView = UIScrollView(frame: container.bounds.inset(by: UIEdgeInsets(top: 40, left: 10, bottom: 10, right: 10)))
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        container.addSubview(scrollView)
        
        let waypoint = viewModel.waypoints[index]
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = waypoint.content
        let maxLabelWidth = scrollView.bounds.width
        let size = label.sizeThatFits(CGSize(width: maxLabelWidth, height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(origin: .zero, size: size)
        scrollView.addSubview(label)
        scrollView.contentSize = size
        
        // Set initial scroll position to previous progress
        let state = viewModel.states[index]
        let scrollOffsetY = CGFloat(state.progress) * max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollOffsetY), animated: false)
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back to Map", for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        backButton.frame = CGRect(x: 12, y: 5, width: 120, height: 30)
        backButton.addTarget(self, action: #selector(closeContent), for: .touchUpInside)
        container.addSubview(backButton)
    }
    
    @objc private func closeContent() {
        contentViewContainer?.removeFromSuperview()
        contentViewContainer = nil
        currentWaypointIndex = nil
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let index = currentWaypointIndex else { return }
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        if contentHeight <= visibleHeight { return }
        
        let progress = Float(scrollView.contentOffset.y / (contentHeight - visibleHeight))
        viewModel.updateProgress(for: index, progress: progress)
        
        // Update dot UI progress ring live
        waypointViews[index].state = viewModel.states[index]
    }
}

// MARK: - SwiftUI Wrapper for Playground

struct ContentView: View {
    var body: some View {
        UIKitWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct UIKitWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ContentViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
