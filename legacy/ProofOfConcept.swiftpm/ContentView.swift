import SwiftUI
import UIKit
import CoreText

// --- Font Registration ---
func registerCustomFonts() {
    let fontNames = [
        "LibreBaskerville-Regular",
        "LibreBaskerville-Bold", 
        "LibreBaskerville-Italic"
    ]
    
    for fontName in fontNames {
        if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") {
            if let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
               let font = CGFont(fontDataProvider) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(font, &error) {
                    print("Successfully registered font: \(fontName)")
                } else {
                    print("Failed to register font: \(fontName), error: \(String(describing: error))")
                }
            }
        } else {
            print("Could not find font file: \(fontName).otf")
        }
    }
}

// --- Wrapper Definitions ---
struct TitleSequenceViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TitleSequenceViewController {
        TitleSequenceViewController()
    }
    func updateUIViewController(_ uiViewController: TitleSequenceViewController, context: Context) {}
}

struct MenuViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MenuViewController {
        MenuViewController()
    }
    func updateUIViewController(_ uiViewController: MenuViewController, context: Context) {}
}

struct HelpViewControllerPlaygroundWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HelpViewController {
        HelpViewController()
    }
    func updateUIViewController(_ uiViewController: HelpViewController, context: Context) {}
}

struct ExtrasMenuViewControllerPlaygroundWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ExtrasMenuViewController {
        let node = ExtrasLoader.loadRootNode() ?? ExtrasNode(title: "Extras", type: "menu", htmlFile: nil, jsonFile: nil, children: [])
        return ExtrasMenuViewController(node: node)
    }
    func updateUIViewController(_ uiViewController: ExtrasMenuViewController, context: Context) {}
}

struct HorizontalStackContainerViewControllerPlaygroundWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HorizontalStackContainerViewController {
        HorizontalStackContainerViewController()
    }
    func updateUIViewController(_ uiViewController: HorizontalStackContainerViewController, context: Context) {}
}

struct WalkumentaryAppPlaygroundWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // Title sequence
        let titleVC = TitleSequenceViewController()
        // Horizontal stack container
        let horizontalStackVC = HorizontalStackContainerViewController()
        // Menu
        let menuVC = MenuViewController()
        // Navigation logic
        menuVC.onNavigate = { destination in
            switch destination {
            case "Help":
                let helpVC = HelpViewController()
                horizontalStackVC.pushFullScreen(helpVC, animated: true)
            case "Extras":
                let extrasVC = ExtrasViewController()
                horizontalStackVC.pushFullScreen(extrasVC, animated: true)
            default:
                break
            }
        }
        // Title sequence completion
        titleVC.onComplete = {
            horizontalStackVC.pushFullScreen(menuVC, animated: false, injectBack: false)
            // Animate transition from titleVC to horizontalStackVC
            guard let window = titleVC.view.window else { return }
            horizontalStackVC.view.frame = CGRect(x: window.bounds.width, y: 0, width: window.bounds.width, height: window.bounds.height)
            window.addSubview(horizontalStackVC.view)
            window.bringSubviewToFront(horizontalStackVC.view)
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
                horizontalStackVC.view.frame = window.bounds
                titleVC.view.frame = CGRect(x: -window.bounds.width, y: 0, width: window.bounds.width, height: window.bounds.height)
            }, completion: { _ in
                // Remove titleVC's view
                titleVC.view.removeFromSuperview()
            })
        }
        // Start with titleVC
        return titleVC
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// --- Additional Wrappers for All Shared ViewControllers ---
struct CautionViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CautionViewController {
        CautionViewController()
    }
    func updateUIViewController(_ uiViewController: CautionViewController, context: Context) {}
}

struct ChapterViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChapterViewController {
        // Dummy Chapter for preview
        let dummyChapter = Chapter(
            id: "preview",
            title: "Preview Chapter", 
            content: "This is a preview chapter content.",
            audioFile: nil,
            imageFile: nil
        )
        return ChapterViewController(chapter: dummyChapter)
    }
    func updateUIViewController(_ uiViewController: ChapterViewController, context: Context) {}
}

struct CreditsViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CreditsViewController {
        CreditsViewController()
    }
    func updateUIViewController(_ uiViewController: CreditsViewController, context: Context) {}
}

struct TourMapViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TourMapViewController {
        TourMapViewController()
    }
    func updateUIViewController(_ uiViewController: TourMapViewController, context: Context) {}
}

struct ChaptersViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChaptersViewController {
        ChaptersViewController()
    }
    func updateUIViewController(_ uiViewController: ChaptersViewController, context: Context) {}
}

struct ExtrasContentViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ExtrasContentViewController {
        let node = ExtrasLoader.loadRootNode() ?? ExtrasNode(title: "Extras Content", type: "page", htmlFile: "Extras.html", jsonFile: nil, children: nil)
        return ExtrasContentViewController(node: node)
    }
    func updateUIViewController(_ uiViewController: ExtrasContentViewController, context: Context) {}
}

struct RecreationsViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RecreationsViewController {
        RecreationsViewController()
    }
    func updateUIViewController(_ uiViewController: RecreationsViewController, context: Context) {}
}

struct ExtrasViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ExtrasViewController {
        ExtrasViewController()
    }
    func updateUIViewController(_ uiViewController: ExtrasViewController, context: Context) {}
}

struct LocationContentViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LocationContentViewController {
        // Dummy TourLocation for preview
        let dummyLocation = TourLocation(
            id: "preview",
            name: "Preview Location", 
            address: "Preview Address",
            latitude: 54.4858,
            longitude: -0.6206,
            contentFragments: []
        )
        return LocationContentViewController(location: dummyLocation)
    }
    func updateUIViewController(_ uiViewController: LocationContentViewController, context: Context) {}
}

// --- Torn Paper View Wrappers ---
struct TornPaperButtonViewWrapper: UIViewRepresentable {
    let title: String
    let isMain: Bool
    
    func makeUIView(context: Context) -> TornPaperButtonView {
        let font = isMain ? Style.menuButtonMainFont : Style.menuButtonFont
        return TornPaperButtonView(title: title, font: font, isMain: isMain)
    }
    
    func updateUIView(_ uiView: TornPaperButtonView, context: Context) {}
}

struct TornPaperTableCellViewWrapper: UIViewRepresentable {
    let title: String
    
    func makeUIView(context: Context) -> TornPaperTableCellView {
        let cell = TornPaperTableCellView(style: .default, reuseIdentifier: "Preview")
        cell.configure(title: title)
        return cell
    }
    
    func updateUIView(_ uiView: TornPaperTableCellView, context: Context) {}
}

// --- Playground View Selection ---
enum PlaygroundView {
    case titleSequence
    case menu
    case help
    case extrasMenu
    case horizontalStack
    case fullApp
    case caution
    case chapter
    case credits
    case tourMap
    case chapters
    case extrasContent
    case recreations
    case extras
    case locationContent
    case tornPaperButton
    case tornPaperTableCell
}

// Set this variable to choose which view to preview
let playgroundViewToShow: PlaygroundView = .tornPaperButton

struct ContentView: View {
    init() {
        // Register fonts when the module loads
        registerCustomFonts()
    }

    var body: some View {
        Group {
            switch playgroundViewToShow {
            case .titleSequence:
                TitleSequenceViewControllerWrapper()
            case .menu:
                MenuViewControllerWrapper()
            case .help:
                HelpViewControllerPlaygroundWrapper()
            case .extrasMenu:
                ExtrasMenuViewControllerPlaygroundWrapper()
            case .horizontalStack:
                HorizontalStackContainerViewControllerPlaygroundWrapper()
            case .fullApp:
                WalkumentaryAppPlaygroundWrapper()
            case .caution:
                CautionViewControllerWrapper()
            case .chapter:
                ChapterViewControllerWrapper()
            case .credits:
                CreditsViewControllerWrapper()
            case .tourMap:
                TourMapViewControllerWrapper()
            case .chapters:
                ChaptersViewControllerWrapper()
            case .extrasContent:
                ExtrasContentViewControllerWrapper()
            case .recreations:
                RecreationsViewControllerWrapper()
            case .extras:
                ExtrasViewControllerWrapper()
            case .locationContent:
                LocationContentViewControllerWrapper()
            case .tornPaperButton:
                VStack(spacing: 20) {
                    TornPaperButtonViewWrapper(title: "Main Button", isMain: true)
                        .frame(width: 360, height: 150)
                    TornPaperButtonViewWrapper(title: "Secondary Button", isMain: false)
                        .frame(width: 360, height: 150)
                }
                .padding()
            case .tornPaperTableCell:
                VStack(spacing: 10) {
                    TornPaperTableCellViewWrapper(title: "Sample Table Cell 1")
                        .frame(height: 60)
                    TornPaperTableCellViewWrapper(title: "Sample Table Cell 2")
                        .frame(height: 60)
                    TornPaperTableCellViewWrapper(title: "Sample Table Cell 3")
                        .frame(height: 60)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
