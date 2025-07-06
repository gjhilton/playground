import Foundation
// NOTE: ResourceProvider protocol is defined in Protocols.swift. Ensure Protocols.swift is included in the target for this file to work.

// MARK: - Default Resource Provider (Xcode/Bundle.main)
class DefaultResourceProvider: ResourceProvider {
    func data(forResource name: String, withExtension ext: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        return try? Data(contentsOf: url)
    }
    func url(forResource name: String, withExtension ext: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}

// MARK: - Playground Resource Provider (stub)
#if canImport(SwiftUI) && targetEnvironment(simulator)
class PlaygroundResourceProvider: ResourceProvider {
    func data(forResource name: String, withExtension ext: String) -> Data? {
        // TODO: Implement for Playgrounds resource access
        return nil
    }
    func url(forResource name: String, withExtension ext: String) -> URL? {
        // TODO: Implement for Playgrounds resource access
        return nil
    }
}
#endif 