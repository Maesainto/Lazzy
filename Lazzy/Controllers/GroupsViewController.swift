import UIKit

final class GroupsViewController: LazzyScreenController, UITableViewDataSource, UITableViewDelegate {
    private let segmentedControl = UISegmentedControl(items: ["Groupes", "Amis"])
    private let tableView = ContentTableView(frame: .zero, style: .plain)
    private let sectionTitle = LazzyTheme.label("Mes groupes", size: 21, weight: .bold)
    private var actionButton: UIButton!
    private let data = MockDataManager.shared
    private var showingFriends: Bool { segmentedControl.selectedSegmentIndex == 1 }

    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = LazzyTheme.green
        segmentedControl.backgroundColor = LazzyTheme.line
        segmentedControl.setTitleTextAttributes([.foregroundColor: LazzyTheme.ink, .font: LazzyTheme.font(14, .semibold)], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.heightAnchor.constraint(equalToConstant: 46).isActive = true
        segmentedControl.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
        segmentedControl.accessibilityIdentifier = "groups.segment"
        contentStack.addArrangedSubview(segmentedControl)
        contentStack.addArrangedSubview(sectionTitle)
        tableView.dataSource = self; tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130
        tableView.register(SocialCell.self, forCellReuseIdentifier: "social")
        contentStack.addArrangedSubview(tableView)
        actionButton = LazzyTheme.button("Créer un groupe", symbol: "plus") { [weak self] in self?.addItem() }
        contentStack.addArrangedSubview(actionButton)
        NotificationCenter.default.addObserver(self, selector: #selector(changeSegment), name: .lazzyGroupsChanged, object: nil)
    }
    @objc private func changeSegment() {
        sectionTitle.text = showingFriends ? "Mes amis · \(data.friends.count)" : "Mes groupes"
        actionButton.configuration?.title = showingFriends ? "Ajouter un ami" : "Créer un groupe"
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { showingFriends ? data.friends.count : data.groups.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "social", for: indexPath) as! SocialCell
        if showingFriends {
            let friend = data.friends[indexPath.row]
            cell.configure(icon: LazzyTheme.avatar(friend.name, color: indexPath.row.isMultiple(of: 2) ? LazzyTheme.lime : LazzyTheme.peach),
                           title: friend.displayName, detail: "\(friend.steps.stepsText) pas aujourd’hui", footer: friend.hasFailed ? "Gage à relever" : "Objectif en cours", compact: true)
        } else {
            let group = data.groups[indexPath.row]
            cell.configure(icon: LazzyTheme.avatar(group.name, image: group.photo, size: 52),
                           title: group.name, detail: "\(group.members.count) membres · \(group.goal.stepsText) pas / jour",
                           footer: "Voir le classement", compact: false)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if showingFriends {
            let friend = data.friends[indexPath.row]
            let navigation = UINavigationController(rootViewController: FriendProfileViewController(friend: friend))
            navigation.modalPresentationStyle = .fullScreen
            present(navigation, animated: true)
        } else {
            let group = data.groups[indexPath.row]
            let detail = RankingViewController(group: group)
            let navigation = UINavigationController(rootViewController: detail)
            navigation.modalPresentationStyle = .fullScreen
            present(navigation, animated: true)
        }
    }
    private func addItem() {
        let alert = UIAlertController(title: showingFriends ? "Ajouter un ami" : "Créer un groupe", message: nil, preferredStyle: .alert)
        let friends = showingFriends
        alert.addTextField { $0.placeholder = friends ? "Pseudo de ton ami" : "Nom du groupe"; $0.autocapitalizationType = .words }
        if !friends { alert.addTextField { $0.placeholder = "Minimum de pas par jour (ex. 10000)"; $0.keyboardType = .numberPad } }
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ajouter", style: .default) { [weak self, weak alert] _ in
            guard let self, let fields = alert?.textFields else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 40 else { self.message("Nom invalide", "Choisis un nom de 1 à 40 caractères."); return }
            if friends {
                guard !self.data.friends.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
                    self.message("Déjà dans ta liste", "Cet ami est déjà présent."); return
                }
                self.data.friends.append(Friend(name: name, steps: 0))
            } else {
                guard let goal = Int(fields[1].text ?? ""), goal > 0 else {
                    self.message("Objectif invalide", "Saisis un nombre entier de pas supérieur à zéro."); return
                }
                self.data.groups.append(WalkingGroup(name: name, symbol: "figure.walk", goal: goal, members: []))
            }
            self.changeSegment()
        })
        present(alert, animated: true)
    }
}

final class ContentTableView: UITableView {
    override var contentSize: CGSize { didSet { invalidateIntrinsicContentSize() } }
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height) }
}
final class SocialCell: UITableViewCell {
    private var card: UIView?
    func configure(icon: UIView, title: String, detail: String, footer: String, compact: Bool) {
        backgroundColor = .clear; selectionStyle = .none
        card?.removeFromSuperview()
        let words = LazzyTheme.stack([LazzyTheme.label(title, size: 16, weight: .bold), LazzyTheme.label(detail, size: 12, color: LazzyTheme.muted)], spacing: 5)
        let top = LazzyTheme.stack([icon, words, LazzyTheme.icon("chevron.right", color: LazzyTheme.muted, size: 12)], axis: .horizontal, spacing: 12)
        top.alignment = .center
        let stack = LazzyTheme.stack([top, LazzyTheme.label(footer, size: 12, weight: .medium, color: compact ? LazzyTheme.muted : LazzyTheme.green)], spacing: 15)
        let card = LazzyTheme.padded(stack, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentView.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([card.topAnchor.constraint(equalTo: contentView.topAnchor), card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)])
        self.card = card
        accessibilityLabel = "\(title), \(detail), \(footer)"
    }
}
