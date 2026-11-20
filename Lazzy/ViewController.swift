import UIKit

final class ViewController: LazzyScreenController {
    private let healthManager = HealthManager()
    private let progressView = CircularProgressView()
    private let stepsLabel = LazzyTheme.label("0", size: 46, weight: .bold, color: .white)
    private let goalLabel = LazzyTheme.label("", size: 13, color: UIColor.white.withAlphaComponent(0.7))
    private let remainingLabel = LazzyTheme.label("", size: 13, weight: .medium, color: .white)
    private let percentLabel = LazzyTheme.label("0 %", size: 14, weight: .bold, color: LazzyTheme.lime)
    private let greetingLabel = LazzyTheme.label("", size: 31, weight: .bold)
    private let profileAvatar = UIImageView()
    private let distanceLabel = LazzyTheme.label("—", size: 19, weight: .bold)
    private let caloriesLabel = LazzyTheme.label("—", size: 19, weight: .bold)
    private let healthLabel = LazzyTheme.label("Lecture de Santé…", size: 12, color: LazzyTheme.muted)
    private let trophyList = LazzyTheme.stack(spacing: 16)
    private let refreshControl = UIRefreshControl()
    private var steps: Double = 0
    private var healthAuthorizationCompleted = false
    private var isRefreshing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildInterface()
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfile), name: .lazzyProfileChanged, object: nil)
        refresh()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfile()
    }
    private func buildInterface() {
        let settings = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.showSettings()
        })
        settings.accessibilityLabel = "Ouvrir mon profil"
        settings.accessibilityIdentifier = "home.profile"
        let avatarSize: CGFloat = 50
        profileAvatar.tintColor = LazzyTheme.green
        profileAvatar.layer.cornerRadius = avatarSize / 2
        profileAvatar.clipsToBounds = true
        profileAvatar.translatesAutoresizingMaskIntoConstraints = false
        settings.addSubview(profileAvatar)
        NSLayoutConstraint.activate([
            settings.widthAnchor.constraint(equalToConstant: 60),
            settings.heightAnchor.constraint(equalToConstant: 60),
            profileAvatar.centerXAnchor.constraint(equalTo: settings.centerXAnchor),
            profileAvatar.centerYAnchor.constraint(equalTo: settings.centerYAnchor),
            profileAvatar.widthAnchor.constraint(equalToConstant: avatarSize),
            profileAvatar.heightAnchor.constraint(equalToConstant: avatarSize)
        ])
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
        contentStack.addArrangedSubview(activityCard())
        contentStack.setCustomSpacing(16, after: progressCard)
        contentStack.addArrangedSubview(LazzyTheme.padded(
            trophyList, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), radius: 20
        ))

        refreshControl.tintColor = LazzyTheme.green
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
    }
    private func activityCard() -> UIView {
        let title = LazzyTheme.label("Activité du jour", size: 16, weight: .bold)
        title.accessibilityTraits.insert(.header)
        let header = LazzyTheme.stack([LazzyTheme.icon("heart.fill", color: LazzyTheme.orange, size: 14), title], axis: .horizontal, spacing: 8)
        header.alignment = .center

        let distance = LazzyTheme.stack([LazzyTheme.label("Distance à pied", size: 12, color: LazzyTheme.muted), distanceLabel], spacing: 4)
        let calories = LazzyTheme.stack([LazzyTheme.label("Calories actives", size: 12, color: LazzyTheme.muted), caloriesLabel], spacing: 4)
        distanceLabel.accessibilityLabel = "Distance à pied indisponible"
        caloriesLabel.accessibilityLabel = "Calories actives indisponibles"
        let metrics = LazzyTheme.stack([distance, calories], axis: .horizontal, spacing: 12)
        metrics.distribution = .fillEqually
        metrics.alignment = .top

        let content = LazzyTheme.stack([header, metrics, healthLabel], spacing: 12)
        return LazzyTheme.padded(content, insets: UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16), radius: 20)
    }
    @objc private func updateProfile() {
        let profile = ProfileStore.shared
        greetingLabel.text = profile.displayName
        let photo = profile.avatar
        profileAvatar.contentMode = photo == nil ? .scaleAspectFit : .scaleAspectFill
        profileAvatar.image = photo ?? UIImage(systemName: "person.crop.circle.fill")
        updateProgress()
        updateTrophyList()
    }
    private func updateTrophyList() {
        trophyList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let heading = LazzyTheme.label("Mes trophées", size: 20, weight: .bold)
        heading.accessibilityTraits.insert(.header)
        trophyList.addArrangedSubview(heading)

        let earnedIDs = Set(TrophyStore.shared.earned.map(\.id))
        for trophy in Trophy.all {
            let earned = earnedIDs.contains(trophy.id)
            let badge: UIView
            if earned {
                let emoji = LazzyTheme.label(trophy.badge, size: 23)
                emoji.textAlignment = .center
                badge = emoji
            } else {
                badge = LazzyTheme.icon("lock.fill", color: LazzyTheme.muted, size: 17)
            }
            badge.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            badge.widthAnchor.constraint(equalToConstant: 32).isActive = true
            badge.heightAnchor.constraint(equalToConstant: 32).isActive = true

            let name = LazzyTheme.label(trophy.name, size: 16, weight: .semibold, color: earned ? LazzyTheme.ink : LazzyTheme.muted)
            let requirement = LazzyTheme.label(trophy.requirement, size: 13, color: LazzyTheme.muted)
            let text = LazzyTheme.stack([name, requirement], spacing: 4)
            let row = LazzyTheme.stack([badge, text], axis: .horizontal, spacing: 10)
            row.alignment = .center
            row.isAccessibilityElement = true
            row.accessibilityIdentifier = "home.trophy.\(trophy.id)"
            row.accessibilityLabel = "\(trophy.name), \(earned ? "obtenu" : "verrouillé"). \(trophy.requirement)"
            trophyList.addArrangedSubview(row)
        }
    }
    private func showSettings() {
        guard let storyboard else { return }
        let settings = storyboard.instantiateViewController(withIdentifier: "settings")
        let navigation = UINavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .fullScreen
        navigation.overrideUserInterfaceStyle = .light
        navigation.navigationBar.tintColor = LazzyTheme.green
        present(navigation, animated: true)
    }
    @objc private func refresh() {
        guard isViewLoaded else { return }
        guard healthManager.isAvailable else {
            #if targetEnvironment(simulator)
            healthLabel.text = "Santé indisponible dans le simulateur"
            #else
            healthLabel.text = "Santé indisponible sur cet appareil"
            #endif
            refreshControl.endRefreshing()
            return
        }
        // Si la première lecture est encore en cours, son résultat terminera
        // aussi la roue du geste manuel, sans lancer de requête en double.
        guard !isRefreshing else { return }
        isRefreshing = true
        Task { [weak self] in
            guard let self else { return }
            defer {
                isRefreshing = false
                refreshControl.endRefreshing()
            }
            if !healthAuthorizationCompleted {
                do {
                    try await healthManager.requestAuthorization()
                    healthAuthorizationCompleted = true
                } catch {
                    healthLabel.text = "Connexion Santé à vérifier · tire vers le bas pour réessayer"
                    return
                }
            }

            let date = Date()
            let calendar = Calendar.current
            let activity = await healthManager.fetchDailyActivity(date: date, calendar: calendar)
            updateActivityCard(activity)
            if let steps = activity.steps, steps < Double(Int.max) {
                self.steps = steps
                TrophyStore.shared.record(steps: Int(steps), goal: ProfileStore.shared.dailyGoal, date: date, calendar: calendar)
                updateProgress()
            }
        }
    }
    private func updateActivityCard(_ activity: HealthManager.DailyActivity) {
        let locale = Locale(identifier: "fr_FR")
        let distance = activity.distanceKilometers.map { "\($0.formatted(.number.locale(locale).precision(.fractionLength(0...2)))) km" }
        let calories = activity.activeKilocalories.map { "\($0.formatted(.number.locale(locale).precision(.fractionLength(0)))) kcal" }
        distanceLabel.text = distance ?? "—"
        distanceLabel.accessibilityLabel = distance ?? "Distance à pied indisponible"
        caloriesLabel.text = calories ?? "—"
        caloriesLabel.accessibilityLabel = calories ?? "Calories actives indisponibles"

        let time = Date().formatted(.dateTime.hour().minute().locale(locale))
        if activity.steps == nil {
            healthLabel.text = "Pas indisponibles · tire vers le bas pour réessayer"
        } else if distance == nil && calories == nil && activity.steps == 0 {
            healthLabel.text = "Aucune donnée Santé accessible · \(time)"
        } else if activity.steps == 0 {
            healthLabel.text = "Aucun pas accessible · \(time)"
        } else {
            healthLabel.text = "Dernière lecture Santé : \(time)"
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
