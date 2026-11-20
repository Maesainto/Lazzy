import UIKit

final class WelcomeViewController: UIViewController, UITextFieldDelegate {
    private let completion: () -> Void
    private let nameField = UITextField()
    private let errorLabel = LazzyTheme.label("Ton pseudo doit contenir entre 1 et 30 caractères.", size: 13, color: LazzyTheme.orange)

    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Utiliser init(completion:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = LazzyTheme.background
        view.tintColor = LazzyTheme.green

        let mark = LazzyTheme.padded(
            LazzyTheme.icon("figure.walk", size: 32),
            insets: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20),
            background: LazzyTheme.lime, radius: 22
        )
        let title = LazzyTheme.label("Bienvenue sur Lazzy", size: 34, weight: .bold)
        title.accessibilityTraits.insert(.header)
        let profile = ProfileStore.shared
        let hasSavedProfile = profile.hasSavedProfile
        let introText = hasSavedProfile
            ? "Ton profil « \(profile.name) » est déjà enregistré sur cet iPhone."
            : "Crée ton profil sur cet iPhone."
        let intro = LazzyTheme.label(introText, size: 16, color: LazzyTheme.muted)
        let header = LazzyTheme.stack([mark, title, intro], spacing: 12)
        header.alignment = .leading
        header.setCustomSpacing(20, after: mark)

        let primary = LazzyTheme.button(hasSavedProfile ? "Continuer" : "Créer un compte") { [weak self] in
            if hasSavedProfile {
                self?.completion()
            } else {
                self?.createProfile()
            }
        }
        primary.accessibilityIdentifier = hasSavedProfile ? "welcome.continue" : "welcome.create"
        let signIn = LazzyTheme.button("Se connecter", filled: false) { [weak self] in self?.showSignInStatus() }
        signIn.accessibilityIdentifier = "welcome.signIn"

        let content = LazzyTheme.stack([header], spacing: 24)
        if !hasSavedProfile { content.addArrangedSubview(profileForm()) }
        content.addArrangedSubview(LazzyTheme.stack([primary, signIn], spacing: 4))

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)
        let safeArea = view.safeAreaLayoutGuide
        let fullWidth = content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        fullWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 48),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            content.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fullWidth
        ])
    }

    private func profileForm() -> UIView {
        nameField.font = LazzyTheme.font(16)
        nameField.textColor = LazzyTheme.ink
        nameField.borderStyle = .roundedRect
        nameField.backgroundColor = .white
        nameField.placeholder = "Ton pseudo"
        nameField.accessibilityLabel = "Pseudo"
        nameField.accessibilityIdentifier = "welcome.name"
        nameField.textContentType = .nickname
        nameField.autocapitalizationType = .words
        nameField.returnKeyType = .go
        nameField.delegate = self
        nameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        nameField.addTarget(self, action: #selector(clearError), for: .editingChanged)
        errorLabel.isHidden = true
        return LazzyTheme.stack([LazzyTheme.label("Pseudo", size: 14, weight: .semibold), nameField, errorLabel], spacing: 8)
    }

    @objc private func clearError() { errorLabel.isHidden = true }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createProfile()
        return false
    }

    private func createProfile() {
        guard let name = ProfileStore.validatedName(nameField.text ?? "") else {
            errorLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: errorLabel.text)
            return
        }
        let profile = ProfileStore.shared
        profile.save(name: name, bio: profile.bio, goal: profile.dailyGoal)
        view.endEditing(true)
        completion()
    }

    private func showSignInStatus() {
        view.endEditing(true)
        let alert = UIAlertController(
            title: "Connexion en ligne indisponible",
            message: "La connexion à un compte sera disponible quand Lazzy sera reliée à son serveur.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Compris", style: .default))
        present(alert, animated: true)
    }
}
