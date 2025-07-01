import SwiftUI
import UIKit

// MARK: - SwiftUI ContentView Entry Point

struct ContentView: View {
    var body: some View {
        // Embeds the UIKit view controller for drill-down snap UI
        UIKitDrillDownSnapView()
            .edgesIgnoringSafeArea(.all) // Full screen
    }
}

// MARK: - UIViewControllerRepresentable to integrate UIKit in SwiftUI

struct UIKitDrillDownSnapView: UIViewControllerRepresentable {
    // Create and return our UIKit view controller
    func makeUIViewController(context: Context) -> UIViewController {
        DrillDownSnapViewController()
    }
    
    // No need to update the controller in this example
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Main UIKit View Controller implementing custom snap scrolling drill down UI

class DrillDownSnapViewController: UIViewController, UIScrollViewDelegate {
    
    // UIScrollView and content container
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    // Array holding the "boxes" (UIView instances)
    var boxes: [UIView] = []
    
    // Spacing between boxes
    let boxSpacing: CGFloat = 20
    
    // Box width is 90% of screen width, dynamically computed
    var boxWidth: CGFloat {
        return view.bounds.width * 0.9
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupScrollView()
        addInitialBox()
    }
    
    // MARK: - Setup Scroll View and Content
    
    func setupScrollView() {
        scrollView.delegate = self
        
        // Use fast deceleration for snappy scrolling feel
        scrollView.decelerationRate = .fast
        
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = true
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Pin scrollView to edges of the main view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Content view holds the horizontally stacked boxes
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Pin contentView edges to scrollView content layout guides
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            // Height equals scrollView height (no vertical scrolling)
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
    }
    
    // MARK: - Initial Box Setup
    
    /// Adds the very first box (light gray) to start drill-down
    func addInitialBox() {
        let box = createBox(color: .lightGray)
        boxes.append(box)
        contentView.addSubview(box)
        
        // Layout the first box without a previous box
        layoutBox(box, after: nil)
        
        // Update trailing constraint on content view to fit all boxes
        updateTrailingConstraint()
    }
    
    // MARK: - Button Tap Handler
    
    /// Called when a color button inside a box is tapped
    @objc func handleButton(_ sender: UIButton) {
        // Find which box contains the tapped button
        guard let box = sender.superview?.superview,
              let idx = boxes.firstIndex(of: box) else { return }
        
        // Remove all boxes to the right of current box
        while boxes.count > idx + 1 {
            boxes.removeLast().removeFromSuperview()
        }
        
        // Define colors corresponding to buttons by their tags
        let colors: [UIColor] = [.red, .green, .blue, .systemPink]
        
        // Create new box of selected color
        let newBox = createBox(color: colors[sender.tag])
        boxes.append(newBox)
        contentView.addSubview(newBox)
        
        // Layout new box immediately after the current one
        layoutBox(newBox, after: box)
        
        // Update contentView trailing constraint to new box
        updateTrailingConstraint()
        
        // Snap scroll view to show newly added box
        snapToBox(at: idx + 1)
    }
    
    // MARK: - Create Box Views
    
    /// Creates a single "box" view with 4 small buttons for colors
    func createBox(color: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = color
        box.layer.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        
        // Vertical stack for buttons, aligned left with spacing
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        box.addSubview(stack)
        
        // Stack pinned near top-left inside box
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 20),
        ])
        
        // Define the button options with their color and label
        let options: [(String, UIColor)] = [
            ("Red", .red),
            ("Green", .green),
            ("Blue", .blue),
            ("Pink", .systemPink)
        ]
        
        // Create buttons and add to stack
        for (i, (title, color)) in options.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.backgroundColor = color.withAlphaComponent(0.85)
            b.setTitleColor(.white, for: .normal)
            b.titleLabel?.font = .boldSystemFont(ofSize: 14)
            b.layer.cornerRadius = 6
            b.tag = i // tag to identify which color tapped
            
            // Assign target action for button tap
            b.addTarget(self, action: #selector(handleButton(_:)), for: .touchUpInside)
            
            b.translatesAutoresizingMaskIntoConstraints = false
            
            // Fixed size for buttons (small)
            b.widthAnchor.constraint(equalToConstant: 80).isActive = true
            b.heightAnchor.constraint(equalToConstant: 36).isActive = true
            
            stack.addArrangedSubview(b)
        }
        
        return box
    }
    
    // MARK: - Layout Helpers
    
    /// Layouts a box horizontally after a given previous box (or start if nil)
    func layoutBox(_ box: UIView, after prev: UIView?) {
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: boxWidth),
            box.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.9),
            box.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        if let previous = prev {
            // Place box after the previous one with spacing
            box.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: boxSpacing).isActive = true
        } else {
            // If no previous box, anchor to contentView leading with spacing
            box.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: boxSpacing).isActive = true
        }
    }
    
    /// Updates the trailing constraint on contentView to fit all boxes properly
    func updateTrailingConstraint() {
        // Remove any existing trailing constraints on contentView
        contentView.constraints
            .filter { $0.firstAnchor == contentView.trailingAnchor || $0.secondAnchor == contentView.trailingAnchor }
            .forEach { $0.isActive = false }
        
        // Anchor trailing of last box to contentView trailing with spacing
        if let last = boxes.last {
            last.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -boxSpacing).isActive = true
        }
    }
    
    // MARK: - Custom Snapping Scroll Logic
    
    /*
     This method controls how the scroll view snaps when dragging ends:
     - For fast swipes (velocity > 0.2), it will snap to next or previous box depending on swipe direction
     - For slow drags, it snaps to the nearest box
     - Clamps snapping so it never scrolls beyond existing boxes
     */
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageWidth = boxWidth + boxSpacing
        let currentOffset = scrollView.contentOffset.x
        let velocityX = velocity.x
        
        var targetPage: CGFloat
        if abs(velocityX) > 0.2 {
            // Swipe velocity — go forward or back
            targetPage = velocityX > 0 ? ceil(currentOffset / pageWidth) : floor(currentOffset / pageWidth)
        } else {
            // Regular drag — snap to nearest box
            targetPage = round(currentOffset / pageWidth)
        }
        
        // Clamp target page between 0 and last box index
        let maxPage = CGFloat(max(0, boxes.count - 1))
        targetPage = max(0, min(targetPage, maxPage))
        
        // Calculate new offset for scroll view contentOffset
        let newOffsetX = targetPage * pageWidth
        targetContentOffset.pointee.x = newOffsetX
    }
    
    /// Scrolls programmatically to the box at given index with animation
    func snapToBox(at index: Int) {
        let x = CGFloat(index) * (boxWidth + boxSpacing)
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
}

// MARK: - Notes & Next Steps

/*
 1. This project uses a hybrid SwiftUI + UIKit approach because UIScrollView snapping
 with custom widths & spacing is more flexible in UIKit currently.
 
 2. Boxes are dynamically created with fixed width = 90% screen width + spacing.
 
 3. Tapping a button:
 - Removes all boxes to the right of the current one
 - Adds a new box of the tapped color to the right
 - Scrolls to new box with smooth snapping
 
 4. Scroll snapping is velocity-aware:
 - Fast swipes move to next/prev box even if partial scroll
 - Slow drags snap to closest box
 
 5. The scrollView and contentView constraints dynamically adjust to content changes.
 
 6. To extend or maintain:
 - Consider adding haptic feedback when snapping for UX polish
 - Add breadcrumb or path indicator above boxes if needed
 - Support dynamic content inside boxes (e.g., text or images)
 - Add accessibility labels and traits for buttons and boxes
 
 7. This is easily extensible for drill down style interfaces or paging flows with custom card widths.
 
 ---
 
 Happy to help pick this back up anytime! Just ask for:
 - More features
 - Code refactoring
 - SwiftUI-only conversion attempts
 - Performance improvements
 - Or UI polish (animations, shadows, etc.)
 */
