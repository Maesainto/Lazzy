import UIKit

final class WallViewController: LazzyScreenController {
    private let data = MockDataManager.shared
    private var photoPicker: PhotoPickerCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Une texture répétée couvre tout l’écran, même au-delà des photos.
        if let image = UIImage(named: "StoneWall") {
            let size = CGSize(width: 360, height: 360 * image.size.height / image.size.width)
            let tile = UIGraphicsImageRenderer(size: size).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            view.backgroundColor = UIColor(patternImage: tile)
        }
        scrollView.backgroundColor = .clear
        scrollView.contentInset.bottom = 96
        scrollView.verticalScrollIndicatorInsets.bottom = 96
        let add = UIButton(type: .system)
        add.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)), for: .normal)
        add.tintColor = .white
        add.backgroundColor = LazzyTheme.orange
        add.layer.cornerRadius = 32
        add.layer.shadowColor = UIColor.black.cgColor
        add.layer.shadowOpacity = 0.22
        add.layer.shadowRadius = 10
        add.layer.shadowOffset = CGSize(width: 0, height: 4)
        add.accessibilityLabel = "Ajouter ma photo"
        add.accessibilityIdentifier = "wall.addPhoto"
        add.addAction(UIAction { [weak self] _ in self?.chooseProof() }, for: .touchUpInside)
        add.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(add)
        NSLayoutConstraint.activate([
            add.widthAnchor.constraint(equalToConstant: 64),
            add.heightAnchor.constraint(equalToConstant: 64),
            add.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            add.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
        rebuildBoard()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        data.removeExpiredProofs()
        if isViewLoaded { rebuildBoard() }
    }
    @objc private func rebuildBoard() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let posts = data.posts
        let left = LazzyTheme.stack([], spacing: 28)
        let offset = UIView(); offset.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let right = LazzyTheme.stack([offset], spacing: 0)
        right.spacing = 28
        for (index, post) in posts.enumerated() {
            let card = photoCard(post)
            card.transform = CGAffineTransform(rotationAngle: index.isMultiple(of: 2) ? -0.035 : 0.04)
            (index.isMultiple(of: 2) ? left : right).addArrangedSubview(card)
        }
        let columns = LazzyTheme.stack([left, right], axis: .horizontal, spacing: 14)
        columns.distribution = .fillEqually; columns.alignment = .top
        contentStack.addArrangedSubview(columns)
    }

    private func photoCard(_ post: ShamePost) -> UIView {
        let photo = UIButton(type: .custom)
        photo.setImage(post.image, for: .normal)
        photo.imageView?.contentMode = .scaleAspectFill
        photo.clipsToBounds = true
        photo.heightAnchor.constraint(equalTo: photo.widthAnchor, multiplier: 1.25).isActive = true
        photo.accessibilityLabel = "Voir la preuve de \(post.name) : \(post.challenge)"
        photo.addAction(UIAction { [weak self] _ in
            let detail = ProofDetailViewController(post: post)
            self?.present(UINavigationController(rootViewController: detail), animated: true)
        }, for: .touchUpInside)
        var config = UIButton.Configuration.plain()
        config.title = "🍅 \(post.likes)"; config.baseForegroundColor = LazzyTheme.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 2, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming; out.font = LazzyTheme.font(12, .semibold); return out
        }
        let tomato = UIButton(configuration: config)
        tomato.accessibilityLabel = "Lancer une tomate à \(post.name), \(post.likes) réactions"
        tomato.addAction(UIAction { [weak self, weak tomato] _ in
            guard let self, let index = self.data.posts.firstIndex(where: { $0.id == post.id }) else { return }
            self.data.posts[index].isLiked.toggle()
            self.data.posts[index].likes += self.data.posts[index].isLiked ? 1 : -1
            let current = self.data.posts[index]
            tomato?.configuration?.title = "🍅 \(current.likes)"
            tomato?.configuration?.baseForegroundColor = current.isLiked ? LazzyTheme.orange : LazzyTheme.ink
            tomato?.accessibilityLabel = "\(current.likes) tomates, \(current.isLiked ? "retirer ma réaction" : "lancer une tomate")"
        }, for: .touchUpInside)
        let stack = LazzyTheme.stack([photo, tomato], spacing: 4)
        let card = LazzyTheme.padded(stack, insets: UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6), radius: 3)
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOpacity = 0.18
        card.layer.shadowOffset = CGSize(width: 0, height: 5); card.layer.shadowRadius = 6
        let tape = UIView(); tape.backgroundColor = UIColor(hex: 0xEBDFC5).withAlphaComponent(0.88)
        tape.translatesAutoresizingMaskIntoConstraints = false; tape.isUserInteractionEnabled = false
        card.addSubview(tape)
        NSLayoutConstraint.activate([tape.widthAnchor.constraint(equalToConstant: 44), tape.heightAnchor.constraint(equalToConstant: 16), tape.centerXAnchor.constraint(equalTo: card.centerXAnchor), tape.topAnchor.constraint(equalTo: card.topAnchor, constant: -7)])
        return card
    }
    private func chooseProof() {
        photoPicker = PhotoPickerCoordinator(owner: self) { [weak self] image in self?.describeProof(image) }
        photoPicker?.present()
    }
    private func describeProof(_ image: UIImage) {
        let alert = UIAlertController(title: "Ton gage, ta preuve", message: "La photo sera enregistrée sur cet iPhone pendant 24 h. Elle n’est pas envoyée aux autres membres.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Quel gage as-tu relevé ?"; $0.autocapitalizationType = .sentences }
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ajouter", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let text = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.count <= 100 else { self.message("Un titre pour ton gage", "Décris ton gage en 1 à 100 caractères."); return }
            do {
                try self.data.addProof(image: image, challenge: text)
                self.rebuildBoard()
            } catch { self.message("Enregistrement impossible", "La photo n’a pas pu être enregistrée. Réessaie après avoir vérifié l’espace disponible.") }
        })
        present(alert, animated: true)
    }
}

final class ProofDetailViewController: UIViewController {
    private let post: ShamePost
    init(post: ShamePost) { self.post = post; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Utiliser init(post:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LazzyTheme.background; title = post.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        let photo = UIImageView(image: post.image); photo.contentMode = .scaleAspectFit
        let caption = LazzyTheme.label(post.challenge, size: 22, weight: .bold); caption.textAlignment = .center
        let note = LazzyTheme.label(post.isDemo ? "Photo de démonstration générée pour la maquette." : "Preuve locale, visible pendant 24 h.", size: 12, color: LazzyTheme.muted); note.textAlignment = .center
        let stack = LazzyTheme.stack([photo, caption, note], spacing: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24), stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)])
        photo.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        caption.setContentHuggingPriority(.required, for: .vertical)
        note.setContentHuggingPriority(.required, for: .vertical)
    }
}
