import UIKit

final class ApplicationView: UIView {
    var initialViewClass: TitlePageViewProtocol.Type
    var pageData: [PageData]?
    
    init(initialViewClass: TitlePageViewProtocol.Type, pageData: [PageData]?) {
        self.initialViewClass = initialViewClass
        self.pageData = pageData
        super.init(frame: .zero)
        backgroundColor = .white
        
        if let pageData = pageData {
            print("ApplicationView received pageData count: \(pageData.count)")
            
            print("ApplicationView received pageData count: \(pageData)")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

