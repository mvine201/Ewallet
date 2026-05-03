import UIKit

final class CustomPieChartView: UIView {
    struct Segment {
        let value: Double
        let color: UIColor
    }

    private let trackLayer = CAShapeLayer()
    private var segmentLayers: [CAShapeLayer] = []
    private let centerStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private var currentSegments: [Segment] = []
    private var currentTitle: String = ""
    private var currentSubtitle: String = ""
    private var shouldAnimate = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerStack.spacing = 4
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        centerStack.addArrangedSubview(titleLabel)
        centerStack.addArrangedSubview(subtitleLabel)
        addSubview(centerStack)

        NSLayoutConstraint.activate([
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderChart()
    }

    func configure(
        segments: [Segment],
        centerTitle: String,
        centerSubtitle: String,
        animated: Bool = true
    ) {
        currentSegments = segments.filter { $0.value > 0 }
        currentTitle = centerTitle
        currentSubtitle = centerSubtitle
        shouldAnimate = animated
        titleLabel.text = centerTitle
        subtitleLabel.text = centerSubtitle
        setNeedsLayout()
    }

    private func renderChart() {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()

        let inset: CGFloat = 10
        let diameter = min(bounds.width, bounds.height) - inset * 2
        guard diameter > 0 else { return }

        let lineWidth = max(18, diameter * 0.18)
        let radius = (diameter - lineWidth) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let ringPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )

        trackLayer.frame = bounds
        trackLayer.path = ringPath.cgPath
        trackLayer.lineWidth = lineWidth

        let total = currentSegments.reduce(0.0) { $0 + $1.value }
        guard total > 0 else { return }

        var startAngle = -CGFloat.pi / 2
        currentSegments.forEach { segment in
            let endAngle = startAngle + CGFloat(segment.value / total) * .pi * 2
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )

            let segmentLayer = CAShapeLayer()
            segmentLayer.frame = bounds
            segmentLayer.path = path.cgPath
            segmentLayer.fillColor = UIColor.clear.cgColor
            segmentLayer.strokeColor = segment.color.cgColor
            segmentLayer.lineWidth = lineWidth
            segmentLayer.lineCap = .round
            layer.addSublayer(segmentLayer)
            segmentLayers.append(segmentLayer)

            if shouldAnimate {
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = 0
                animation.toValue = 1
                animation.duration = 0.55
                animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                segmentLayer.add(animation, forKey: "strokeEnd")
            }

            startAngle = endAngle
        }
    }
}

extension UIColor {
    convenience init?(analyticsHex: String) {
        let hex = analyticsHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
