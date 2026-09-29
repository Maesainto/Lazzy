import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var progressView: CircularProgressView!
    @IBOutlet weak var stepsLabel: UILabel! // À ajouter au centre de ton cercle sur le Storyboard
    
    let healthManager = HealthManager()
    let dailyGoal: Double = 10000.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // On demande l'autorisation
        healthManager.requestAuthorization { [weak self] success in
            if success {
                self?.loadSteps()
            }
        }
    }
    
    func loadSteps() {
        healthManager.fetchTodaySteps { [weak self] steps in
            // Les mises à jour de l'interface doivent TOUJOURS se faire sur le thread principal
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Mettre à jour le texte
                self.stepsLabel.text = "\(Int(steps)) / \(Int(self.dailyGoal))"
                
                // Lancer l'animation du cercle
                self.progressView.setProgress(steps: steps, goal: self.dailyGoal)
            }
        }
    }
}
