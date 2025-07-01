import SwiftUI

// Define a Codable struct for parsing the JSON
struct MenuNode: Codable {
    var viewClass: String
    var data: [String: String]
    var label: String?
    var children: [MenuNode]?
    
    // Coding keys to map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case viewClass
        case data
        case label
        case children
    }
}

// A simple view for displaying menu data
struct MenuView: View {
    var node: MenuNode
    
    var body: some View {
        VStack {
            // Display the title or label
            if let title = node.data["title"] {
                Text(title)
                    .font(.title)
                    .padding()
            }
            
            // If there are children, show them as a list of labels
            if let children = node.children {
                List(children, id: \.viewClass) { child in
                    Text(child.data["title"] ?? "Unknown")
                }
            }
        }
        .padding()
    }
}

// ContentView to load the JSON data and show the first root node
struct ContentView: View {
    @State private var rootNode: MenuNode?
    
    // Load the JSON data and parse it
    func loadData() {
        let jsonString = """
        [
          {
            "viewClass": "SplashscreenView",
            "data": {
              "title": "Hello"
            }
          },
          {
            "viewClass": "RootMenuView",
            "data": {
              "title": "Root menu"
            },
            "children": [
              {
                "viewClass": "MenuView",
                "label": "Tour",
                "data": {
                  "title": "Tour menu"
                },
                "children": [
                  {
                    "viewClass": "LeafNodeView",
                    "label": "Location A",
                    "data": {
                      "title": "Location A",
                      "content": "Lorem ipsum dolor..."
                    }
                  },
                  {
                    "viewClass": "LeafNodeView",
                    "label": "Location B",
                    "data": {
                      "title": "Location B",
                      "content": "Lorem ipsum dolor..."
                    }
                  }
                ]
              },
              {
                "viewClass": "LeafNodeView",
                "label": "Browse",
                "data": {
                  "title": "Browse",
                  "content": "Lorem ipsum dolor..."
                }
              },
              {
                "viewClass": "LeafNodeView",
                "label": "Extras",
                "data": {
                  "title": "Extras",
                  "content": "Lorem ipsum dolor..."
                }
              }
            ]
          }
        ]
        """
        
        // Convert JSON string to Data
        if let jsonData = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                // Decode the data into an array of MenuNode objects
                let nodes = try decoder.decode([MenuNode].self, from: jsonData)
                // Load the first node (root node)
                self.rootNode = nodes.first
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack {
            if let rootNode = rootNode {
                // Show the menu view for the root node
                MenuView(node: rootNode)
            } else {
                // Show a loading message or placeholder
                Text("Loading...")
                    .onAppear {
                        loadData()
                    }
            }
        }
        .padding()
    }
}

// SwiftUI Preview for testing the ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
