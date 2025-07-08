import SwiftUI

// MARK: - Models

struct Waypoint: Identifiable, Hashable {
    let id: Int
    let title: String
}

struct Chapter: Identifiable, Hashable {
    let id: Int
    let title: String
}

// Removed Hashable conformance from MenuItem
struct MenuItem {
    let id = UUID()
    let title: String
    let action: () -> Void
}

enum Screen: Hashable {
    case home
    case map(tourMode: Bool)
    case extras
    case help
    case waypoint(Waypoint)
    case book
    case chapter(Chapter)
    case whitby
    case credits
}

// MARK: - ViewModel

final class AppViewModel: ObservableObject {
    @Published var path: [Screen] = []
    
    let waypoints: [Waypoint]
    let chapters: [Chapter]
    
    init() {
        // Initialize waypoints and chapters with dummy data
        self.waypoints = (1...6).map { Waypoint(id: $0, title: "Waypoint \($0)") }
        self.chapters = (1...20).map { Chapter(id: $0, title: "Chapter \($0)") }
    }
    
    // Navigation helpers
    func goToHome() {
        path.removeAll()
    }
    
    func push(_ screen: Screen) {
        path.append(screen)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    // Placeholder HTML content generator
    func placeholderHTMLContent(title: String) -> String {
        """
        <h1>\(title)</h1>
        <p>This is placeholder HTML content for the \(title) screen.</p>
        """
    }
    
    // Menu item generators for Extras and Book
    var extrasMenuItems: [MenuItem] {
        [
            MenuItem(title: "Book") { [weak self] in self?.push(.book) },
            MenuItem(title: "More Whitby") { [weak self] in self?.push(.whitby) },
            MenuItem(title: "Credits") { [weak self] in self?.push(.credits) }
        ]
    }
    
    var bookMenuItems: [MenuItem] {
        chapters.map { chapter in
            MenuItem(title: chapter.title) { [weak self] in self?.push(.chapter(chapter)) }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            HomeSceneView(
                onTourTap: { viewModel.push(.map(tourMode: true)) },
                onBrowseTap: { viewModel.push(.map(tourMode: false)) },
                onExtrasTap: { viewModel.push(.extras) },
                onHelpTap: { viewModel.push(.help) }
            )
            .navigationTitle("Home")
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .map(let tourMode):
                    MapSceneView(
                        tourMode: tourMode,
                        onSelectWaypoint: { waypoint in
                            viewModel.push(.waypoint(waypoint))
                        }
                    )
                    .navigationTitle("Map")
                case .extras:
                    MenuSceneView(
                        title: "Extras",
                        buttons: viewModel.extrasMenuItems,
                        onBack: viewModel.pop
                    )
                    .navigationTitle("Extras")
                case .book:
                    MenuSceneView(
                        title: "Book",
                        buttons: viewModel.bookMenuItems,
                        onBack: viewModel.pop
                    )
                    .navigationTitle("Book")
                case .waypoint(let waypoint):
                    WaypointSceneView(
                        waypoint: waypoint,
                        totalWaypoints: viewModel.waypoints.count,
                        onNext: {
                            if let currentIndex = viewModel.waypoints.firstIndex(of: waypoint),
                               currentIndex + 1 < viewModel.waypoints.count {
                                let nextWaypoint = viewModel.waypoints[currentIndex + 1]
                                viewModel.push(.waypoint(nextWaypoint))
                            }
                        }
                    )
                    .navigationTitle(waypoint.title)
                case .help:
                    HtmlSceneView(
                        title: "Help",
                        htmlContent: viewModel.placeholderHTMLContent(title: "Help"),
                        onBack: viewModel.pop
                    )
                    .navigationTitle("Help")
                case .chapter(let chapter):
                    HtmlSceneView(
                        title: chapter.title,
                        htmlContent: viewModel.placeholderHTMLContent(title: chapter.title),
                        onBack: viewModel.pop
                    )
                    .navigationTitle(chapter.title)
                case .whitby:
                    HtmlSceneView(
                        title: "More Whitby",
                        htmlContent: viewModel.placeholderHTMLContent(title: "More Whitby"),
                        onBack: viewModel.pop
                    )
                    .navigationTitle("More Whitby")
                case .credits:
                    HtmlSceneView(
                        title: "Credits",
                        htmlContent: viewModel.placeholderHTMLContent(title: "Credits"),
                        onBack: viewModel.pop
                    )
                    .navigationTitle("Credits")
                case .home:
                    EmptyView() // root handled separately
                }
            }
        }
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
            
            Button("Tour", action: onTourTap)
                .buttonStyle(.borderedProminent)
            Button("Browse", action: onBrowseTap)
                .buttonStyle(.borderedProminent)
            Button("Extras", action: onExtrasTap)
                .buttonStyle(.bordered)
            Button("Help", action: onHelpTap)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - MenuSceneView

struct MenuSceneView: View {
    let title: String
    let buttons: [MenuItem]
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.largeTitle).bold()
            
            ForEach(buttons, id: \.id) { item in
                Button(item.title, action: item.action)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            Button("Back", action: onBack)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - MapSceneView

struct MapSceneView: View {
    let tourMode: Bool
    let onSelectWaypoint: (Waypoint) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Map (Tour Mode: \(tourMode ? "On" : "Off"))")
                .font(.largeTitle).bold()
            
            Button("Go to Waypoint 1") {
                onSelectWaypoint(Waypoint(id: 1, title: "Waypoint 1"))
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - WaypointSceneView

struct WaypointSceneView: View {
    let waypoint: Waypoint
    let totalWaypoints: Int
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(waypoint.title)
                .font(.largeTitle).bold()
            
            Text("Details for \(waypoint.title) go here.")
                .padding()
            
            if waypoint.id < totalWaypoints {
                Button("Next Waypoint", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
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
