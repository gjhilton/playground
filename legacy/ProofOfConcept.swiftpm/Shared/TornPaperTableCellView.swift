import UIKit

class TornPaperTableCellView: UITableViewCell {
    private let tornPaperLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = Style.backgroundColor
        selectionStyle = .none
        layer.masksToBounds = false
        contentView.layer.insertSublayer(tornPaperLayer, at: 0)
        
        titleLabel.font = Style.menuButtonFont
        titleLabel.textColor = Style.textColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tornPaperLayer.frame = bounds
        tornPaperLayer.path = createTornPaperPath(in: bounds).cgPath
        tornPaperLayer.fillColor = Style.backgroundColor.cgColor
        tornPaperLayer.shadowColor = UIColor.black.cgColor
        tornPaperLayer.shadowOpacity = 0.18
        tornPaperLayer.shadowRadius = 6
        tornPaperLayer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    private func createTornPaperPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let n = Style.tornEdgeVertices
        let amplitude = Style.tornEdgeVerticalJitter
        let hJitter = Style.tornEdgeHorizontalJitter
        // Top edge
        var x: CGFloat = 0
        path.move(to: CGPoint(x: 0, y: 0))
        for i in 1..<n {
            let dx = width / CGFloat(n-1)
            x += dx + CGFloat.random(in: -hJitter...hJitter)
            let y = CGFloat.random(in: -amplitude...amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: 0))
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height))
        // Bottom edge
        x = width
        for i in (1..<n).reversed() {
            let dx = width / CGFloat(n-1)
            x -= dx + CGFloat.random(in: -hJitter...hJitter)
            let y = height + CGFloat.random(in: -amplitude...amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        return path
    }
} 