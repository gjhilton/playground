import Foundation

struct ExtrasNode: Codable {
    let title: String
    let type: String // "menu", "externalMenu", or "page"
    let htmlFile: String?
    let jsonFile: String?
    let children: [ExtrasNode]?
}

class ExtrasLoader {
    static var resourceProvider: ResourceProvider = DefaultResourceProvider()
    static func loadRootNode() -> ExtrasNode? {
        return loadNode(from: "Extras.json")
    }
    static func loadNode(from jsonFile: String) -> ExtrasNode? {
        let fileName = jsonFile.replacingOccurrences(of: ".json", with: "")
        guard let data = resourceProvider.data(forResource: fileName, withExtension: "json") else { return nil }
        do {
            let node = try JSONDecoder().decode(ExtrasNode.self, from: data)
            return node
        } catch {
            print("Failed to load or decode \(jsonFile): \(error)")
            return nil
        }
    }
} 