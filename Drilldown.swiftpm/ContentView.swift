import SwiftUI

enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case object([String: CodableValue])
    case array([CodableValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: CodableValue].self) {
            self = .object(v)
        } else if let v = try? container.decode([CodableValue].self) {
            self = .array(v)
        } else {
            throw DecodingError.typeMismatch(CodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for CodableValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        case .object(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        }
    }
    
    var anyValue: Any? {
        switch self {
        case .string(let v): return v
        case .int(let v): return v
        case .double(let v): return v
        case .bool(let v): return v
        case .null: return nil
        case .object(let v): return v.mapValues { $0.anyValue }
        case .array(let v): return v.compactMap { $0.anyValue }
        }
    }
}

struct CodablePageData: Codable {
    let viewClass: String?
    let label: String?
    let data: [String: CodableValue]?
    let children: [CodablePageData]?
}

struct PageData {
    let viewClass: String?
    let data: [String: Any]?
    let children: [PageData]?
    let label: String?
    
    init(from codable: CodablePageData) {
        viewClass = codable.viewClass
        label = codable.label
        if let codableData = codable.data {
            var tempDict = [String: Any]()
            for (key, value) in codableData {
                tempDict[key] = value.anyValue
            }
            data = tempDict
        } else {
            data = nil
        }
        if let codableChildren = codable.children {
            children = codableChildren.map { PageData(from: $0) }
        } else {
            children = nil
        }
    }
}

final class ApplicationViewController {
    let view: ApplicationView
    private let initialViewClass: TitlePageViewProtocol.Type
    
    private let applicationConfigJSON = """
    {
        "viewClass": "MenuPageView",
        "children": [
            {
                "viewClass": "MenuPageView",
                "label": "Tour",
                "children": [
                    {
                        "viewClass": "PlaceholderPageView",
                        "label": "Location A",
                        "data": {
                            "title": "Location A"
                        }
                    },
                    {
                        "viewClass": "PlaceholderPageView",
                        "label": "Location B",
                        "data": {
                            "title": "Location B"
                        }
                    }
                ]
            },
            {
                "viewClass": "PlaceholderPageView",
                "label": "Browse",
                "data": {
                    "title": "Browse placeholder"
                }
            },
            {
                "viewClass": "PlaceholderPageView",
                "label": "Extras",
                "data": {
                    "title": "Extras placeholder"
                }
            }
        ]
    }
    """
    
    init(initialViewClass: TitlePageViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        
        var parsedPageData: PageData? = nil
        if let data = applicationConfigJSON.data(using: .utf8) {
            do {
                let rootCodablePage = try JSONDecoder().decode(CodablePageData.self, from: data)
                parsedPageData = PageData(from: rootCodablePage)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        self.view = ApplicationView(initialViewClass: initialViewClass, pageData: parsedPageData)
        setup()
    }
    
    private func setup() {
        // Additional setup if needed
    }
}

struct ApplicationViewRepresentable: UIViewRepresentable {
    let initialViewClass: TitlePageViewProtocol.Type
    
    func makeUIView(context: Context) -> UIView {
        let controller = ApplicationViewController(initialViewClass: initialViewClass)
        return controller.view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct ContentView: View {
    var body: some View {
        ApplicationViewRepresentable(initialViewClass: TitlePageView.self)
    }
}
