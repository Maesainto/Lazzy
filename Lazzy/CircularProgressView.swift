import UIKit

class CircularProgressView: UIView {
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        self.backgroundColor = .clear
        
        // Le tracé du cercle (commence en haut à -90 degrés)
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                        radius: bounds.width / 2,
                                        startAngle: -CGFloat.pi / 2,
                                        endAngle: 1.5 * CGFloat.pi,
                                        clockwise: true)
        
        // Le cercle de fond (gris clair)
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        trackLayer.lineWidth = 15 // Épaisseur du trait
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        
        // Le cercle de progression (qui va s'animer)
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemGreen.cgColor // Couleur de remplissage
        progressLayer.lineWidth = 15
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0 // Initialisé à 0% au démarrage
        layer.addSublayer(progressLayer)
    }
    
    // Fonction à appeler pour mettre à jour et animer la barre
    func setProgress(steps: Double, goal: Double) {
        let currentProgress = min(steps / goal, 1.0) // min() empêche de dépasser un tour complet visuellement
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 1.5 // Durée de l'animation en secondes
        animation.toValue = currentProgress
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        progressLayer.add(animation, forKey: "progressAnim")
    }
}
