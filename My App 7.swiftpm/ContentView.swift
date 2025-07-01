import SwiftUI
import UIKit

// MARK: - Helpers for Color persistence

extension Color {
    static func fromData(_ data: Data) -> Color? {
        guard
            let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor
        else { return nil }
        return Color(uiColor)
    }
    
    func toData() -> Data? {
        UIColor(self).encode()
    }
}

extension UIColor {
    func encode() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
}

// MARK: - Theme Model

struct Theme: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let fontSize: Double
    let lineSpacing: Double
    let fontDesignRaw: String
    let textColor: Color
    let backgroundColor: Color
}

// MARK: - Predefined Themes

let themes: [Theme] = [
    Theme(
        name: "Default",
        fontSize: 16,
        lineSpacing: 6,
        fontDesignRaw: "serif",
        textColor: .primary,
        backgroundColor: Color(.secondarySystemBackground)
    ),
    Theme(
        name: "Night",
        fontSize: 18,
        lineSpacing: 8,
        fontDesignRaw: "default",
        textColor: .white,
        backgroundColor: .black
    ),
    Theme(
        name: "Sepia",
        fontSize: 18,
        lineSpacing: 10,
        fontDesignRaw: "serif",
        textColor: Color(red: 60/255, green: 40/255, blue: 20/255),
        backgroundColor: Color(red: 244/255, green: 236/255, blue: 212/255)
    ),
    Theme(
        name: "Mono",
        fontSize: 20,
        lineSpacing: 4,
        fontDesignRaw: "monospaced",
        textColor: .green,
        backgroundColor: .black
    )
]

// MARK: - Cached Procedural Paper Texture View

struct CachedPaperTexture: View {
    @State private var textureImage: Image?
    
    var body: some View {
        GeometryReader { geo in
            if let textureImage = textureImage {
                textureImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.global(qos: .userInitiated).async {
                            let uiImage = generatePaperTexture(size: geo.size)
                            let swiftUIImage = Image(uiImage: uiImage)
                            DispatchQueue.main.async {
                                self.textureImage = swiftUIImage
                            }
                        }
                    }
            }
        }
        .cornerRadius(12)
    }
    
    func generatePaperTexture(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        let img = renderer.image { ctx in
            let context = ctx.cgContext
            
            // Base gradient
            let colors = [UIColor(red: 1, green: 0.97, blue: 0.9, alpha: 1).cgColor,
                          UIColor(red: 0.96, green: 0.9, blue: 0.7, alpha: 1).cgColor]
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
            
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: size.width/2, y: 0),
                                       end: CGPoint(x: size.width/2, y: size.height),
                                       options: [])
            
            // Grain noise
            let grainCount = Int(size.width * size.height / 900)
            for _ in 0..<grainCount {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let radius = CGFloat.random(in: 0.3...1.1)
                let opacity = CGFloat.random(in: 0.015...0.06)
                context.setFillColor(UIColor.black.withAlphaComponent(opacity).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
            }
            
            // Creases (diagonal lines)
            context.setStrokeColor(UIColor(white: 1, alpha: 0.07).cgColor)
            context.setLineWidth(1.1)
            let creaseSpacing: CGFloat = 50
            for i in stride(from: -size.height, through: size.width, by: creaseSpacing) {
                context.move(to: CGPoint(x: i, y: 0))
                context.addLine(to: CGPoint(x: i + size.height, y: size.height))
                context.strokePath()
            }
            
            // Coffee stains (blobs)
            context.setFillColor(UIColor.brown.withAlphaComponent(0.08).cgColor)
            for _ in 0..<10 {
                let centerX = CGFloat.random(in: size.width * 0.15...size.width * 0.85)
                let centerY = CGFloat.random(in: size.height * 0.1...size.height * 0.9)
                let maxRadius = CGFloat.random(in: 30...70)
                
                let path = UIBezierPath()
                let segments = 12
                for i in 0...segments {
                    let angle = CGFloat(i) / CGFloat(segments) * 2 * CGFloat.pi
                    let radius = maxRadius * (0.7 + 0.3 * CGFloat.random(in: 0...1))
                    let x = centerX + radius * cos(angle)
                    let y = centerY + radius * sin(angle)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.close()
                context.addPath(path.cgPath)
                context.fillPath()
            }
        }
        return img
    }
}

// MARK: - Main View

struct ContentView: View {
    @AppStorage("fontSize") private var fontSize: Double = 16
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6
    @AppStorage("fontDesign") private var fontDesignRaw: String = "serif"
    
    @AppStorage("textColorData") private var textColorData: Data = UIColor.label.encode()!
    @AppStorage("bgColorData") private var bgColorData: Data = UIColor.secondarySystemBackground.encode()!
    
    @State private var showingSettings = false
    
    let loremIpsum = String(repeating: """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \
    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. \
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. \
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    """, count: 50)
    
    var fontDesign: Font.Design {
        switch fontDesignRaw {
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }
    
    var textColor: Color {
        Color.fromData(textColorData) ?? .primary
    }
    
    var backgroundColor: Color {
        Color.fromData(bgColorData) ?? Color(.secondarySystemBackground)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .padding()
                }
            }
            
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack {
                        Text(loremIpsum)
                            .font(.system(size: fontSize, design: fontDesign))
                            .lineSpacing(lineSpacing)
                            .foregroundColor(textColor)
                            .padding(30)
                            .frame(maxWidth: geo.size.width * 0.6)
                            .background(
                                CachedPaperTexture()
                                    .frame(width: geo.size.width * 0.6)
                            )
                            .cornerRadius(12)
                            .padding(.vertical, 50)
                    }
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor.edgesIgnoringSafeArea(.all))
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                fontSize: $fontSize,
                lineSpacing: $lineSpacing,
                fontDesignRaw: $fontDesignRaw,
                textColorData: $textColorData,
                bgColorData: $bgColorData
            )
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var fontSize: Double
    @Binding var lineSpacing: Double
    @Binding var fontDesignRaw: String
    
    @Binding var textColorData: Data
    @Binding var bgColorData: Data
    
    @Environment(\.presentationMode) var presentationMode
    
    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color.fromData(textColorData) ?? .primary },
            set: { textColorData = $0.toData() ?? textColorData }
        )
    }
    
    private var bgColorBinding: Binding<Color> {
        Binding(
            get: { Color.fromData(bgColorData) ?? Color(.secondarySystemBackground) },
            set: { bgColorData = $0.toData() ?? bgColorData }
        )
    }
    
    func applyTheme(_ theme: Theme) {
        fontSize = theme.fontSize
        lineSpacing = theme.lineSpacing
        fontDesignRaw = theme.fontDesignRaw
        textColorData = theme.textColor.toData() ?? textColorData
        bgColorData = theme.backgroundColor.toData() ?? bgColorData
    }
    
    func resetDefaults() {
        if let defaultTheme = themes.first(where: { $0.name == "Default" }) {
            applyTheme(defaultTheme)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Themes")) {
                    Picker("Select Theme", selection: Binding(
                        get: {
                            themes.first(where: { theme in
                                theme.fontSize == fontSize &&
                                theme.lineSpacing == lineSpacing &&
                                theme.fontDesignRaw == fontDesignRaw &&
                                theme.textColor.toData() == textColorData &&
                                theme.backgroundColor.toData() == bgColorData
                            })?.id ?? themes[0].id
                        },
                        set: { newId in
                            if let theme = themes.first(where: { $0.id == newId }) {
                                applyTheme(theme)
                            }
                        })) {
                            ForEach(themes) { theme in
                                Text(theme.name).tag(theme.id)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    
                    Button("Reset to Defaults", action: resetDefaults)
                        .foregroundColor(.red)
                }
                
                Section(header: Text("Text Settings")) {
                    Stepper(value: $fontSize, in: 12...50, step: 1) {
                        Text("Font Size: \(Int(fontSize))")
                    }
                    
                    Stepper(value: $lineSpacing, in: 0...30, step: 1) {
                        Text("Line Spacing: \(Int(lineSpacing))")
                    }
                    
                    Picker("Font Design", selection: $fontDesignRaw) {
                        Text("Default").tag("default")
                        Text("Serif").tag("serif")
                        Text("Monospaced").tag("monospaced")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Colors")) {
                    ColorPicker("Text Color", selection: textColorBinding)
                    ColorPicker("Background Color", selection: bgColorBinding)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Preview for Xcode (Optional)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
