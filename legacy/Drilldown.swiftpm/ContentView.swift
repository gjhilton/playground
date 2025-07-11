import SwiftUI

// MARK: - CodableValue

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
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                CodableValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Wrong type for CodableValue"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        }
    }
    
    var anyValue: Any? {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .null: return nil
        case .object(let value): return value.mapValues(\.anyValue)
        case .array(let value): return value.compactMap(\.anyValue)
        }
    }
}

// MARK: - CodablePageData

struct CodablePageData: Codable {
    let viewClass: String?
    let label: String?
    let data: [String: CodableValue]?
    let children: [CodablePageData]?
}

// MARK: - PageData

struct PageData {
    let viewClass: String?
    let data: [String: Any]?
    let children: [PageData]?
    let label: String?
    
    init(from codable: CodablePageData) {
        viewClass = codable.viewClass
        label = codable.label
        data = codable.data?.mapValues(\.anyValue)
        children = codable.children?.map { PageData(from: $0) }
    }
}

// MARK: - ApplicationViewController

final class ApplicationViewController {
    let view: ApplicationView
    private let initialViewClass: TitlePageViewProtocol.Type
    
    init(initialViewClass: TitlePageViewProtocol.Type) {
        self.initialViewClass = initialViewClass
        
        if let url = Bundle.main.url(forResource: "config", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let rootCodablePage = try? JSONDecoder().decode(CodablePageData.self, from: data) {
            
            let parsedPageData = PageData(from: rootCodablePage)
            view = ApplicationView(initialViewClass: initialViewClass, pageData: parsedPageData)
        } else {
            print("❌ Failed to load or decode config.json")
            view = ApplicationView(initialViewClass: initialViewClass, pageData: nil)
        }
        
        setup()
    }
    
    private func setup() {
        // Additional setup if needed
    }
}

// MARK: - ApplicationViewRepresentable

struct ApplicationViewRepresentable: UIViewRepresentable {
    let initialViewClass: TitlePageViewProtocol.Type
    
    func makeUIView(context: Context) -> UIView {
        ApplicationViewController(initialViewClass: initialViewClass).view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        ApplicationViewRepresentable(initialViewClass: TitlePageView.self)
    }
}
