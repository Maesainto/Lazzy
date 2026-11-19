import UIKit

final class TrophiesViewController: UITableViewController {
    private let friend: Friend?
    private let metrics: [Trophy.Metric] = [.dailySteps, .totalSteps, .goalDays]
    private var earned: [Trophy] { friend?.trophies ?? TrophyStore.shared.earned }
    private var equipped: Trophy? { friend == nil ? TrophyStore.shared.equipped : friend?.equippedTrophy }
    init(friend: Friend? = nil) { self.friend = friend; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(friend:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trophées"
        view.backgroundColor = LazzyTheme.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "trophy")
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .lazzyProfileChanged, object: nil)
        reload()
    }
    @objc private func reload() {
        guard isViewLoaded else { return }
        let name = friend?.displayName ?? ProfileStore.shared.displayName
        let label = LazzyTheme.label("\(name)\n\(earned.count) / \(Trophy.all.count) trophées", size: 22, weight: .bold)
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 110)
        tableView.tableHeaderView = label
        tableView.reloadData()
    }
    private func trophies(_ section: Int) -> [Trophy] { Trophy.all.filter { $0.metric == metrics[section] } }
    override func numberOfSections(in tableView: UITableView) -> Int { metrics.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { trophies(section).count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["En une journée", "Pas cumulés", "Jours validés"][section]
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trophy = trophies(indexPath.section)[indexPath.row]
        let unlocked = earned.contains { $0.id == trophy.id }
        let cell = tableView.dequeueReusableCell(withIdentifier: "trophy", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(trophy.badge)  \(trophy.name)"
        content.textProperties.color = unlocked ? LazzyTheme.ink : LazzyTheme.muted
        content.textProperties.numberOfLines = 0
        var detail = trophy.requirement
        if equipped?.id == trophy.id { detail += "\nBadge équipé" }
        else if unlocked { detail += "\nObtenu" }
        else if friend == nil {
            detail += "\n\(min(TrophyStore.shared.value(for: trophy.metric), trophy.target).stepsText) / \(trophy.target.stepsText)"
        }
        content.secondaryText = detail; content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        let symbol = unlocked ? (equipped?.id == trophy.id ? "checkmark.seal.fill" : "checkmark.circle") : "lock.fill"
        let icon = LazzyTheme.icon(symbol, color: unlocked ? LazzyTheme.green : LazzyTheme.muted, size: 20)
        icon.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        cell.accessoryView = icon
        cell.selectionStyle = friend == nil && unlocked ? .default : .none
        cell.accessibilityIdentifier = "trophy.\(trophy.id)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trophy = trophies(indexPath.section)[indexPath.row]
        guard friend == nil, earned.contains(where: { $0.id == trophy.id }) else { return }
        let isEquipped = equipped?.id == trophy.id
        let alert = UIAlertController(title: "\(trophy.badge) \(trophy.name)", message: trophy.requirement, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: isEquipped ? "Retirer le badge" : "Équiper le badge", style: .default) { _ in
            TrophyStore.shared.equip(isEquipped ? nil : trophy.id)
        })
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alert, animated: true)
    }
}

final class FriendProfileViewController: UIViewController {
    private let friend: Friend
    init(friend: Friend) { self.friend = friend; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(friend:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profil"
        view.backgroundColor = LazzyTheme.background
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        let header = LazzyTheme.stack([LazzyTheme.avatar(friend.name, size: 86),
            LazzyTheme.label(friend.displayName, size: 28, weight: .bold)], spacing: 14)
        header.alignment = .center
        let bio = (friend.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = LazzyTheme.padded(LazzyTheme.stack([
            LazzyTheme.label("Bio", size: 14, weight: .semibold), LazzyTheme.label(bio.isEmpty ? "Aucune bio" : bio, size: 16),
            LazzyTheme.label("Minimum de pas par jour", size: 14, weight: .semibold),
            LazzyTheme.label("\(friend.dailyGoal.stepsText) pas", size: 22, weight: .bold),
            LazzyTheme.label("\(friend.steps.stepsText) pas aujourd’hui", size: 14, color: LazzyTheme.muted)
        ], spacing: 12))
        let trophies = LazzyTheme.button("Trophées · \(friend.trophies.count) / \(Trophy.all.count)", symbol: "trophy") { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(TrophiesViewController(friend: self.friend), animated: true)
        }
        let stack = LazzyTheme.stack([header, profile, trophies, LazzyTheme.label("Trophées obtenus", size: 21, weight: .bold)], spacing: 24)
        if friend.trophies.isEmpty { stack.addArrangedSubview(LazzyTheme.label("Aucun trophée", color: LazzyTheme.muted)) }
        for trophy in friend.trophies {
            stack.addArrangedSubview(LazzyTheme.padded(LazzyTheme.stack([
                LazzyTheme.label("\(trophy.badge) \(trophy.name)", size: 16, weight: .semibold),
                LazzyTheme.label(trophy.requirement, size: 13, color: LazzyTheme.muted)
            ], spacing: 6)))
        }
        let scroll = UIScrollView(); scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll); scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor), stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }
}
