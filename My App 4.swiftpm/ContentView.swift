import Foundation
import CoreGraphics
import CoreText

enum FontManager {
    enum Environment {
        case playground
        case xcode
    }
    
    struct Configuration {
        static var environment: Environment = .playground
    }
    
    static let fontFileNames: [String] = [
        "YourFont1.ttf",
        "YourFont2.otf"
    ]
    
    static func registerFonts() {
        fontFileNames
            .compactMap { makeFontURL(for: $0) }
            .forEach { registerFont(at: $0) }
    }
    
    private static func makeFontURL(for fileName: String) -> URL? {
        switch Configuration.environment {
        case .playground:
            return Bundle.main.url(forResource: fileName, withExtension: nil)
        case .xcode:
            guard let path = Bundle.main.resourcePath else { return nil }
            return URL(fileURLWithPath: path).appendingPathComponent(fileName)
        }
    }
    
    private static func registerFont(at url: URL) {
        guard let dataProvider = CGDataProvider(url: url as CFURL),
              let font = CGFont(dataProvider) else {
            return
        }
        
        _ = CTFontManagerRegisterGraphicsFont(font, nil)
    }
}
