import UIKit

final class ViewController: LazzyScreenController {
    private let healthManager = HealthManager()
    private let progressView = CircularProgressView()
    private let stepsLabel = LazzyTheme.label("0", size: 46, weight: .bold, color: .white)
    private let goalLabel = LazzyTheme.label("", size: 13, color: UIColor.white.withAlphaComponent(0.7))
    private let remainingLabel = LazzyTheme.label("", size: 13, weight: .medium, color: .white)
    private let percentLabel = LazzyTheme.label("0 %", size: 14, weight: .bold, color: LazzyTheme.lime)
    private let greetingLabel = LazzyTheme.label("", size: 31, weight: .bold)
    private let healthLabel = LazzyTheme.label("Connexion à Santé…", size: 12, color: LazzyTheme.muted)
    private let refreshControl = UIRefreshControl()
    private var isLoadingHealthDetails = false
    private var steps: Double = 0
    private var healthAuthorizationCompleted = false
    private var isRefreshing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildInterface()
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfile), name: .lazzyProfileChanged, object: nil)
        healthManager.requestAuthorization { [weak self] success in
            guard let self else { return }
            self.healthAuthorizationCompleted = success
            if success { self.refresh() } else {
                self.healthLabel.text = self.healthManager.isAvailable ? "Connexion Santé à vérifier" : "Santé indisponible dans le simulateur"
                self.refreshControl.endRefreshing()
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfile()
    }
    private func buildInterface() {
        let settings = LazzyTheme.button("", symbol: "person.crop.circle.fill", filled: false) { [weak self] in self?.tabBarController?.selectedIndex = 3 }
        settings.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        settings.configuration?.contentInsets = .zero
        settings.widthAnchor.constraint(equalToConstant: 60).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 60).isActive = true
        settings.accessibilityLabel = "Ouvrir mon profil"
        settings.accessibilityIdentifier = "home.profile"
        contentStack.addArrangedSubview(LazzyTheme.row(greetingLabel, settings))

        let top = LazzyTheme.row(LazzyTheme.label("Ton minimum de pas du jour", size: 15, weight: .semibold, color: .white),
                                LazzyTheme.icon("figure.walk", color: LazzyTheme.lime, size: 20))
        let ringContainer = UIView()
        ringContainer.heightAnchor.constraint(equalToConstant: 242).isActive = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        ringContainer.addSubview(progressView)
        let center = LazzyTheme.stack([LazzyTheme.icon("shoeprints.fill", color: LazzyTheme.lime, size: 24), stepsLabel, goalLabel], spacing: 6)
        center.alignment = .center
        center.translatesAutoresizingMaskIntoConstraints = false
        ringContainer.addSubview(center)
        stepsLabel.adjustsFontSizeToFitWidth = true
        stepsLabel.minimumScaleFactor = 0.6
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: ringContainer.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 230), progressView.heightAnchor.constraint(equalToConstant: 230),
            center.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor), center.centerYAnchor.constraint(equalTo: ringContainer.centerYAnchor),
            center.widthAnchor.constraint(lessThanOrEqualToConstant: 185)
        ])
        let divider = UIView(); divider.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let card = LazzyTheme.stack([top, ringContainer, divider, LazzyTheme.row(remainingLabel, percentLabel)], spacing: 14)
        let progressCard = LazzyTheme.padded(card, background: LazzyTheme.green, radius: 30)
        contentStack.addArrangedSubview(progressCard)
        let healthRow = LazzyTheme.stack([LazzyTheme.icon("heart.fill", color: LazzyTheme.orange, size: 13), healthLabel], axis: .horizontal, spacing: 7)
        healthRow.alignment = .center
        contentStack.addArrangedSubview(healthRow)
        let healthDetails = LazzyTheme.button("Détails Santé", symbol: "info.circle", filled: false) { [weak self] in
            self?.showHealthDetails()
        }
        contentStack.addArrangedSubview(healthDetails)
        contentStack.setCustomSpacing(10, after: progressCard)

        let section = LazzyTheme.row(LazzyTheme.label("À plusieurs, on va plus loin.", size: 18, weight: .bold), LazzyTheme.badge("DÉMO"))
        contentStack.addArrangedSubview(section)
        let teaser = LazzyTheme.stack([
            LazzyTheme.label("Le campus est en marche", size: 17, weight: .bold),
            LazzyTheme.label("Retrouve ta bande, compare vos pas et relevez le défi ensemble.", size: 14, color: LazzyTheme.muted),
            LazzyTheme.button("Voir mes groupes", symbol: "arrow.up.right", filled: false) { [weak self] in self?.tabBarController?.selectedIndex = 2 }
        ], spacing: 10)
        contentStack.addArrangedSubview(LazzyTheme.padded(teaser))
        refreshControl.tintColor = LazzyTheme.green
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
    }
    @objc private func updateProfile() {
        greetingLabel.text = ProfileStore.shared.displayName
        updateProgress()
    }
    private func showHealthDetails() {
        guard !isLoadingHealthDetails else { return }
        isLoadingHealthDetails = true
        let displayedSteps = Int(steps)
        healthManager.fetchStepDiagnostics { [weak self] details in
            guard let self else { return }
            self.isLoadingHealthDetails = false
            self.message("Détails Santé", "Compteur Lazzy au moment de la demande : \(displayedSteps) pas\n\n\(details)")
        }
    }
    @objc private func refresh() {
        guard isViewLoaded else { return }
        guard healthManager.isAvailable else {
            healthLabel.text = "Santé indisponible dans le simulateur"
            refreshControl.endRefreshing()
            return
        }
        guard healthAuthorizationCompleted else { refreshControl.endRefreshing(); return }
        // Si la première lecture est encore en cours, son résultat terminera
        // aussi la roue du geste manuel, sans lancer de requête en double.
        guard !isRefreshing else { return }
        isRefreshing = true
        healthManager.fetchTodayStepsResult { [weak self] result in
            guard let self else { return }
            self.isRefreshing = false
            switch result {
            case .success(let steps):
                self.steps = max(0, steps)
                if steps.isFinite, steps >= 0, steps < Double(Int.max) {
                    TrophyStore.shared.record(steps: Int(steps), goal: ProfileStore.shared.dailyGoal)
                }
                let time = Date().formatted(.dateTime.hour().minute().second().locale(Locale(identifier: "fr_FR")))
                self.healthLabel.text = steps > 0 ? "Dernière lecture Santé : \(time)" : "Santé : aucun pas accessible · \(time)"
            case .failure:
                self.healthLabel.text = self.healthManager.isAvailable ? "Santé : tire vers le bas pour réessayer" : "Santé indisponible dans le simulateur"
            }
            self.updateProgress()
            self.refreshControl.endRefreshing()
        }
    }
    private func updateProgress() {
        let goal = ProfileStore.shared.dailyGoal
        stepsLabel.text = Int(steps).stepsText
        goalLabel.text = "sur \(goal.stepsText) pas"
        remainingLabel.text = steps >= Double(goal) ? "Objectif atteint. Bien joué !" : "Encore \(max(0, goal - Int(steps)).stepsText) pas. Tu peux le faire !"
        remainingLabel.numberOfLines = 2
        percentLabel.text = "\(Int(min(steps / Double(goal), 1) * 100)) %"
        progressView.setProgress(steps: steps, goal: Double(goal))
        progressView.isAccessibilityElement = true
        progressView.accessibilityLabel = "\(Int(steps)) pas sur un objectif de \(goal)"
    }
}
