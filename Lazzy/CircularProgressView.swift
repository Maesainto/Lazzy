import UIKit

final class CircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) { super.init(frame: frame); setupLayers() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupLayers() }

    private func setupLayers() {
        backgroundColor = .clear
        for shape in [trackLayer, progressLayer] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 17
            shape.lineCap = .round
            layer.addSublayer(shape)
        }
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        progressLayer.strokeColor = LazzyTheme.lime.cgColor
        progressLayer.strokeEnd = 0
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = max(0, min(bounds.width, bounds.height) / 2 - 12)
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: radius,
                                startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true).cgPath
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.path = path; progressLayer.path = path
        CATransaction.commit()
    }
    func setProgress(steps: Double, goal: Double) {
        let value = goal > 0 && steps.isFinite && goal.isFinite ? CGFloat(min(max(steps / goal, 0), 1)) : 0
        let from = progressLayer.presentation()?.strokeEnd ?? progress
        progress = value
        progressLayer.strokeEnd = value
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = from; animation.toValue = value; animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.add(animation, forKey: "progress")
    }
}
