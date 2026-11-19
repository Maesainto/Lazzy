import UIKit

final class RankingViewController: UITableViewController {
    private let groupID: UUID
    private let data = MockDataManager.shared
    private var group: WalkingGroup? { data.groups.first { $0.id == groupID } }
    private var members: [Friend] {
        (group?.members ?? []).sorted { $0.steps == $1.steps ? $0.name < $1.name : $0.steps > $1.steps }
    }
    init(group: WalkingGroup) { groupID = group.id; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(group:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Classement"
        navigationItem.backButtonDisplayMode = .minimal
        view.backgroundColor = LazzyTheme.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "rank")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Groupes", style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(editGroup))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Paramètres du groupe"
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "group.settings"
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMember))
        add.accessibilityLabel = "Ajouter un membre"
        add.accessibilityIdentifier = "group.addMember"
        toolbarItems = [UIBarButtonItem(systemItem: .flexibleSpace), add, UIBarButtonItem(systemItem: .flexibleSpace)]
        NotificationCenter.default.addObserver(self, selector: #selector(reloadGroup), name: .lazzyGroupsChanged, object: nil)
        reloadGroup()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
        reloadGroup()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let size = header.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width, height: 0),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        if abs(header.frame.height - size.height) > 0.5 || header.frame.width != tableView.bounds.width {
            header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: size.height)
            tableView.tableHeaderView = header
        }
    }
    @objc private func reloadGroup() {
        guard isViewLoaded, let group else { return }
        let labels = LazzyTheme.stack([LazzyTheme.label(group.name, size: 23, weight: .bold),
            LazzyTheme.label("Minimum : \(group.goal.stepsText) pas / jour", size: 14, color: LazzyTheme.muted)], spacing: 8)
        let row = LazzyTheme.stack([LazzyTheme.avatar(group.name, image: group.photo, size: 64), labels], axis: .horizontal, spacing: 16)
        row.alignment = .center
        let header = LazzyTheme.padded(row, background: .clear, radius: 0)
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 110)
        tableView.tableHeaderView = header
        let empty = LazzyTheme.label("Aucun membre", size: 16, color: LazzyTheme.muted)
        empty.textAlignment = .center
        tableView.backgroundView = members.isEmpty ? empty : nil
        tableView.reloadData()
    }
    @objc private func close() { dismiss(animated: true) }
    @objc private func editGroup() {
        guard let group else { return }
        navigationController?.pushViewController(GroupSettingsViewController(group: group), animated: true)
    }
    @objc private func addMember() {
        guard let group else { return }
        let picker = GroupMemberPicker(groupID: group.id)
        present(UINavigationController(rootViewController: picker), animated: true)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rank", for: indexPath)
        guard let group else { return cell }
        let member = members[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(indexPath.row + 1).  \(member.displayName)"
        content.secondaryText = "\(member.steps.stepsText) / \(group.goal.stepsText) pas"
        content.image = UIImage(systemName: member.steps >= group.goal ? "checkmark.seal.fill" : "figure.walk")
        content.imageProperties.tintColor = LazzyTheme.green
        cell.contentConfiguration = content; cell.selectionStyle = .none
        let remove = UIButton(type: .system)
        remove.setImage(UIImage(systemName: "person.badge.minus"), for: .normal)
        remove.tintColor = LazzyTheme.orange
        remove.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        remove.accessibilityLabel = "Retirer \(member.name) du groupe"
        remove.addAction(UIAction { [weak self] _ in self?.confirmRemoval(member) }, for: .touchUpInside)
        cell.accessoryView = remove
        return cell
    }
    private func confirmRemoval(_ member: Friend) {
        let alert = UIAlertController(title: "Retirer \(member.name) ?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert.addAction(UIAlertAction(title: "Retirer du groupe", style: .destructive) { [weak self] _ in
            guard let self, var group = self.group else { return }
            group.members.removeAll { $0.id == member.id }
            self.data.updateGroup(group)
        })
        present(alert, animated: true)
    }
}

private final class GroupMemberPicker: UITableViewController {
    private let groupID: UUID
    private let data = MockDataManager.shared
    private var candidates: [Friend] {
        let memberIDs = Set(data.groups.first { $0.id == groupID }?.members.map(\.id) ?? [])
        return data.friends.filter { !memberIDs.contains($0.id) }
    }
    init(groupID: UUID) { self.groupID = groupID; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(groupID:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ajouter un membre"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "friend")
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        if candidates.isEmpty {
            let label = LazzyTheme.label("Aucun ami à ajouter", size: 16, color: LazzyTheme.muted)
            label.textAlignment = .center; tableView.backgroundView = label
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { candidates.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friend", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = candidates[indexPath.row].name; content.image = UIImage(systemName: "person.crop.circle")
        cell.contentConfiguration = content
        cell.accessoryType = .none
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = candidates[indexPath.row]
        guard var group = data.groups.first(where: { $0.id == groupID }), !group.members.contains(where: { $0.id == friend.id }) else { return }
        group.members.append(friend)
        data.updateGroup(group)
        dismiss(animated: true)
    }
}

private final class GroupSettingsViewController: UIViewController {
    private let groupID: UUID
    private let nameField = UITextField()
    private let goalField = UITextField()
    private let avatarContainer = UIStackView()
    private var pendingPhoto: UIImage?
    private var photoPicker: PhotoPickerCoordinator?
    init(group: WalkingGroup) { groupID = group.id; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(group:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Paramètres du groupe"
        view.backgroundColor = LazzyTheme.background
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Enregistrer", style: .prominent, target: self, action: #selector(save))
        guard let group = MockDataManager.shared.groups.first(where: { $0.id == groupID }) else { return }
        nameField.text = group.name; goalField.text = String(group.goal)
        nameField.autocapitalizationType = .words
        goalField.keyboardType = .numberPad
        for (field, label, identifier) in [(nameField, "Nom du groupe", "group.name"), (goalField, "Minimum de pas par jour", "group.goal")] {
            field.borderStyle = .roundedRect; field.font = LazzyTheme.font(17)
            field.accessibilityLabel = label; field.accessibilityIdentifier = identifier
            field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(title: "Terminé", style: .prominent, target: self, action: #selector(closeKeyboard))]
        nameField.inputAccessoryView = toolbar; goalField.inputAccessoryView = toolbar
        avatarContainer.axis = .vertical; avatarContainer.alignment = .center
        updateAvatar(group.photo)
        let photo = LazzyTheme.button("Modifier la photo", symbol: "camera", filled: false) { [weak self] in
            guard let self else { return }
            self.view.endEditing(true)
            self.photoPicker = PhotoPickerCoordinator(owner: self) { [weak self] image in
                self?.pendingPhoto = image; self?.updateAvatar(image)
            }
            self.photoPicker?.present()
        }
        let stack = LazzyTheme.stack([avatarContainer, photo,
            LazzyTheme.stack([LazzyTheme.label("Nom du groupe", size: 14, weight: .semibold), nameField]),
            LazzyTheme.stack([LazzyTheme.label("Minimum de pas par jour", size: 14, weight: .semibold), goalField])], spacing: 22)
        let scroll = UIScrollView(); scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll); scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    @objc private func closeKeyboard() { view.endEditing(true) }
    private func updateAvatar(_ image: UIImage?) {
        avatarContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        avatarContainer.addArrangedSubview(LazzyTheme.avatar(nameField.text ?? "", image: image, size: 96))
    }
    @objc private func save() {
        view.endEditing(true)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 40, let goal = Int(goalField.text ?? ""), goal > 0 else {
            let alert = UIAlertController(title: "Paramètres invalides", message: "Nom de 1 à 40 caractères et minimum de pas supérieur à zéro.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true); return
        }
        let data = MockDataManager.shared
        guard var group = data.groups.first(where: { $0.id == groupID }) else { return }
        let previousPhoto = group.photoFile
        do {
            if let pendingPhoto {
                guard let bytes = pendingPhoto.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileWriteUnknown) }
                let filename = "group-\(groupID)-\(UUID()).jpg"
                try bytes.write(to: LocalStore.fileURL(filename), options: .atomic)
                group.photoFile = filename
            }
            group.name = name; group.goal = goal
            data.updateGroup(group)
            if group.photoFile != previousPhoto, let previousPhoto { try? FileManager.default.removeItem(at: LocalStore.fileURL(previousPhoto)) }
            navigationController?.popViewController(animated: true)
        } catch {
            let alert = UIAlertController(title: "Photo non enregistrée", message: "Vérifie l’espace disponible puis réessaie.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
        }
    }
}
