import UIKit

final class SettingsViewController: LazzyScreenController, UITextFieldDelegate {
    private let nameField = UITextField()
    private let bioField = UITextField()
    private let goalField = UITextField()
    private let avatarContainer = UIView()
    private let badgePreview = LazzyTheme.label("", size: 20, weight: .bold)
    private var trophiesButton: UIButton!
    private var pendingAvatar: UIImage?
    private var photoPicker: PhotoPickerCoordinator?
    private let saveStatus = LazzyTheme.label("", size: 12, weight: .medium, color: LazzyTheme.green)

    override func viewDidLoad() {
        super.viewDidLoad()
        heading("À ton image", title: "Tes paramètres.", subtitle: "Ton profil, ton rythme, tes petits défis.")
        avatarContainer.heightAnchor.constraint(equalToConstant: 86).isActive = true
        let changePhoto = LazzyTheme.button("Modifier la photo", symbol: "camera", filled: false) { [weak self] in self?.choosePhoto() }
        let profileHeader = LazzyTheme.stack([avatarContainer, badgePreview, changePhoto], spacing: 8)
        badgePreview.textAlignment = .center
        contentStack.addArrangedSubview(profileHeader)
        trophiesButton = LazzyTheme.button("Mes trophées", symbol: "trophy", filled: false) { [weak self] in
            let navigation = UINavigationController(rootViewController: TrophiesViewController())
            navigation.modalPresentationStyle = .fullScreen
            self?.present(navigation, animated: true)
        }
        trophiesButton.accessibilityIdentifier = "profile.trophies"
        contentStack.addArrangedSubview(trophiesButton)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTrophies), name: .lazzyProfileChanged, object: nil)

        configure(nameField, placeholder: "Ton pseudo", identifier: "profile.name")
        nameField.autocapitalizationType = .words
        nameField.textContentType = .nickname
        configure(bioField, placeholder: "Quelques mots sur toi", identifier: "profile.bio")
        bioField.autocapitalizationType = .sentences
        configure(goalField, placeholder: "10000", identifier: "profile.goal")
        goalField.keyboardType = .numberPad
        goalField.accessibilityLabel = "Nombre minimum de pas par jour"
        let form = LazzyTheme.stack([
            LazzyTheme.label("MON PROFIL", size: 11, weight: .bold, color: LazzyTheme.muted),
            fieldRow("Pseudo", field: nameField), fieldRow("Bio", field: bioField),
            fieldRow("Nombre minimum de pas par jour", field: goalField),
            LazzyTheme.label("Le minimum de pas à atteindre chaque jour. Les groupes ont leur propre minimum.", size: 12, color: LazzyTheme.muted)
        ], spacing: 18)
        contentStack.addArrangedSubview(LazzyTheme.padded(form))
        let save = LazzyTheme.button("Enregistrer les modifications", symbol: "checkmark") { [weak self] in self?.saveProfile() }
        save.accessibilityIdentifier = "profile.save"
        contentStack.addArrangedSubview(save)
        saveStatus.isHidden = true
        saveStatus.accessibilityIdentifier = "profile.status"
        contentStack.addArrangedSubview(saveStatus)

        let health = LazzyTheme.button("Connexion Apple Santé", symbol: "heart", filled: false) { [weak self] in
            self?.message("Tes pas, via Apple Santé", "Lazzy lit uniquement ton nombre de pas du jour.\n\nPour vérifier l’accès, ouvre Santé, puis ton profil et la liste des apps autorisées. Un compteur à zéro peut aussi signifier qu’aucune donnée n’est accessible.\n\nSur le simulateur, aucun pas fictif n’est ajouté.")
        }
        contentStack.addArrangedSubview(LazzyTheme.padded(LazzyTheme.stack([
            health,
            LazzyTheme.label("Les informations de ton profil sont enregistrées sur cet iPhone.", size: 12, color: LazzyTheme.muted)
        ], spacing: 6)))
        contentStack.addArrangedSubview(LazzyTheme.stack([
            LazzyTheme.label("LAZZY · MARCHE OU HONTE", size: 11, weight: .heavy),
            LazzyTheme.label("Projet SAÉ · ISA NUM\nODD 3 — Bonne santé et bien-être", size: 12, color: LazzyTheme.muted)
        ], spacing: 8))
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(title: "Terminé", style: .prominent, target: self, action: #selector(closeKeyboard))]
        [nameField, bioField, goalField].forEach { $0.inputAccessoryView = toolbar }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let profile = ProfileStore.shared
        nameField.text = profile.name; bioField.text = profile.bio; goalField.text = String(profile.dailyGoal)
        pendingAvatar = nil
        updateAvatar(profile.avatar)
        updateTrophies()
    }
    @objc private func updateTrophies() {
        badgePreview.text = ProfileStore.shared.displayName
        trophiesButton?.configuration?.title = "Mes trophées · \(TrophyStore.shared.earned.count) / \(Trophy.all.count)"
    }
    private func configure(_ field: UITextField, placeholder: String, identifier: String) {
        field.placeholder = placeholder
        field.font = LazzyTheme.font(16)
        field.textColor = LazzyTheme.ink
        field.backgroundColor = LazzyTheme.background
        field.layer.cornerRadius = 12
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftView = padding; field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.delegate = self
        field.accessibilityIdentifier = identifier
        field.accessibilityLabel = placeholder
        field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
    }
    private func fieldRow(_ title: String, field: UITextField) -> UIView {
        LazzyTheme.stack([LazzyTheme.label(title, size: 13, weight: .semibold), field], spacing: 8)
    }
    private func updateAvatar(_ image: UIImage?) {
        avatarContainer.subviews.forEach { $0.removeFromSuperview() }
        let avatar = LazzyTheme.avatar(ProfileStore.shared.name, image: image, size: 86)
        avatarContainer.addSubview(avatar)
        NSLayoutConstraint.activate([avatar.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor), avatar.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor)])
    }
    private func choosePhoto() {
        view.endEditing(true)
        photoPicker = PhotoPickerCoordinator(owner: self) { [weak self] image in
            self?.pendingAvatar = image; self?.updateAvatar(image); self?.fieldChanged()
        }
        photoPicker?.present()
    }
    private func saveProfile() {
        view.endEditing(true)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bio = (bioField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...30).contains(name.count) else { message("Pseudo invalide", "Ton pseudo doit contenir entre 1 et 30 caractères."); return }
        guard bio.count <= 120 else { message("Bio trop longue", "Limite ta bio à 120 caractères."); return }
        guard let goal = Int(goalField.text ?? ""), goal > 0 else { message("Objectif invalide", "Saisis un nombre entier de pas supérieur à zéro."); return }
        do {
            if let pendingAvatar { try ProfileStore.shared.saveAvatar(pendingAvatar) }
            ProfileStore.shared.save(name: name, bio: bio, goal: goal)
            pendingAvatar = nil
            updateAvatar(ProfileStore.shared.avatar)
            saveStatus.text = "✓ Profil enregistré sur cet iPhone."
            saveStatus.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: "Profil enregistré")
        } catch { message("Photo non enregistrée", "Impossible d’enregistrer la photo. Vérifie l’espace disponible puis réessaie.") }
    }
    @objc private func closeKeyboard() { view.endEditing(true) }
    @objc private func fieldChanged() { saveStatus.isHidden = true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
    @objc private func keyboardChanged(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let local = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - local.minY - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
        if overlap > 0, let field = [nameField, bioField, goalField].first(where: \.isFirstResponder) {
            scrollView.scrollRectToVisible(field.convert(field.bounds.insetBy(dx: 0, dy: -20), to: scrollView), animated: true)
        }
    }
}
