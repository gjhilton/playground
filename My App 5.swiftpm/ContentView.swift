import SwiftUI

struct ContentView: View {
    // MARK: - Screen Enum
    
    enum Screen: Equatable {
        case home
        case map(tourMode: Bool)
        case extras
        case help
        case waypoint(num: Int)
        case book
        case chapter(num: Int)
        case whitby
        case credits
    }
    
    @State private var currentScreen: Screen = .home
    
    // MARK: - Constants
    
    let totalWaypoints = 6
    let totalChapters = 20
    
    // Placeholder HTML content string
    func placeholderHTMLContent(title: String) -> String {
        """
        <h1>\(title)</h1>
        <p>This is placeholder HTML content for the \(title) screen.</p>
        """
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            switch currentScreen {
            case .home:
                HomeSceneView(
                    onTourTap: { currentScreen = .map(tourMode: true) },
                    onBrowseTap: { currentScreen = .map(tourMode: false) },
                    onExtrasTap: { currentScreen = .extras },
                    onHelpTap: { currentScreen = .help }
                )
            case .extras:
                MenuSceneView(
                    title: "Extras",
                    buttons: [
                        ("Book", { currentScreen = .book }),
                        ("More Whitby", { currentScreen = .whitby }),
                        ("Credits", { currentScreen = .credits })
                    ],
                    onBack: { currentScreen = .home }
                )
            case .book:
                MenuSceneView(
                    title: "Book",
                    buttons: (1...totalChapters).map { chapterNum in
                        ("Chapter \(chapterNum)", { currentScreen = .chapter(num: chapterNum) })
                    },
                    onBack: { currentScreen = .extras }
                )
            case .map(let tourMode):
                MapSceneView(
                    tourMode: tourMode,
                    onSelectWaypoint: { num in currentScreen = .waypoint(num: num) },
                    onBack: { currentScreen = .home }
                )
            case .waypoint(let num):
                WaypointSceneView(
                    waypointNumber: num,
                    totalWaypoints: totalWaypoints,
                    onNext: {
                        if num < totalWaypoints {
                            currentScreen = .waypoint(num: num + 1)
                        }
                    },
                    onBack: { currentScreen = .map(tourMode: true) } // assume returning to Map in tour mode
                )
            case .help:
                HtmlSceneView(
                    title: "Help",
                    htmlContent: placeholderHTMLContent(title: "Help"),
                    onBack: { currentScreen = .home }
                )
            case .chapter(let num):
                HtmlSceneView(
                    title: "Chapter \(num)",
                    htmlContent: placeholderHTMLContent(title: "Chapter \(num)"),
                    onBack: { currentScreen = .book }
                )
            case .whitby:
                HtmlSceneView(
                    title: "More Whitby",
                    htmlContent: placeholderHTMLContent(title: "More Whitby"),
                    onBack: { currentScreen = .extras }
                )
            case .credits:
                HtmlSceneView(
                    title: "Credits",
                    htmlContent: placeholderHTMLContent(title: "Credits"),
                    onBack: { currentScreen = .extras }
                )
            }
        }
        .padding()
        .animation(.default, value: currentScreen)
    }
}

// MARK: - HomeSceneView

struct HomeSceneView: View {
    let onTourTap: () -> Void
    let onBrowseTap: () -> Void
    let onExtrasTap: () -> Void
    let onHelpTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Home").font(.largeTitle).bold()
            
            Button("Tour") { onTourTap() }
                .buttonStyle(.borderedProminent)
            Button("Browse") { onBrowseTap() }
                .buttonStyle(.borderedProminent)
            Button("Extras") { onExtrasTap() }
                .buttonStyle(.bordered)
            Button("Help") { onHelpTap() }
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - MenuSceneView

struct MenuSceneView: View {
    let title: String
    let buttons: [(String, () -> Void)]
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.largeTitle).bold()
            
            ForEach(Array(buttons.enumerated()), id: \.offset) { _, button in
                Button(button.0, action: button.1)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            Button("Back", action: onBack)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - MapSceneView

struct MapSceneView: View {
    let tourMode: Bool
    let onSelectWaypoint: (Int) -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Map (Tour Mode: \(tourMode ? "On" : "Off"))")
                .font(.largeTitle).bold()
            
            Button("Go to Waypoint 1") {
                onSelectWaypoint(1)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            Button("Back", action: onBack)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - WaypointSceneView

struct WaypointSceneView: View {
    let waypointNumber: Int
    let totalWaypoints: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Waypoint \(waypointNumber)")
                .font(.largeTitle).bold()
            
            Text("Details for waypoint \(waypointNumber) go here.")
                .padding()
            
            if waypointNumber < totalWaypoints {
                Button("Next Waypoint") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
            
            Button("Back to Map", action: onBack)
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - HtmlSceneView

struct HtmlSceneView: View {
    let title: String
    let htmlContent: String
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            Text(title).font(.largeTitle).bold()
            
            ScrollView {
                // Since Swift Playgrounds can't render HTML directly,
                // we'll just show the raw string with some simple formatting.
                Text(htmlContent
                    .replacingOccurrences(of: "<h1>", with: "\n\n")
                    .replacingOccurrences(of: "</h1>", with: "\n\n")
                    .replacingOccurrences(of: "<p>", with: "")
                    .replacingOccurrences(of: "</p>", with: "\n")
                )
                .padding()
                .font(.body)
                .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button("Back", action: onBack)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
