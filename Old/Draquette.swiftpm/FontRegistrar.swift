import CoreText
import Foundation

struct FontRegistrar {
    static func registerFont(withName name: String, fileExtension: String) {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            print("Failed to find font file \(name).\(fileExtension)")
            return
        }
        
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
        
        if let error = error?.takeUnretainedValue() {
            print("Failed to register font: \(error)")
        } else {
            print("Successfully registered font: \(name)")
        }
    }
}
