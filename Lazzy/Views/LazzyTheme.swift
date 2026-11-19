import UIKit

enum LazzyTheme {
    static let background = UIColor(hex: 0xF7F5EF)
    static let ink = UIColor(hex: 0x203C33)
    static let muted = UIColor(hex: 0x777C72)
    static let green = UIColor(hex: 0x285A45)
    static let lime = UIColor(hex: 0xDCE9BA)
    static let orange = UIColor(hex: 0xC8512E)
    static let peach = UIColor(hex: 0xF6E2D6)
    static let line = UIColor(hex: 0xE5E6DD)

    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }
    static func label(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular,
                      color: UIColor = ink) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font(size, weight)
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }
    static func stack(_ views: [UIView] = [], axis: NSLayoutConstraint.Axis = .vertical,
                      spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = axis
        stack.spacing = spacing
        return stack
    }
    static func button(_ title: String, symbol: String? = nil, filled: Bool = true,
                       action: @escaping () -> Void) -> UIButton {
        var config = filled ? UIButton.Configuration.filled() : UIButton.Configuration.plain()
        config.title = title
        config.baseBackgroundColor = green
        config.baseForegroundColor = filled ? .white : green
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 18, bottom: 15, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font(15, .semibold)
            return outgoing
        }
        if let symbol { config.image = UIImage(systemName: symbol); config.imagePadding = 8 }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.accessibilityLabel = title
        return button
    }
    static func badge(_ text: String, color: UIColor = green, background: UIColor = lime) -> UIView {
        let label = label(text, size: 11, weight: .bold, color: color)
        return padded(label, insets: UIEdgeInsets(top: 7, left: 11, bottom: 7, right: 11), background: background, radius: 13)
    }
    static func padded(_ content: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
                       background: UIColor = .white, radius: CGFloat = 24) -> UIView {
        let view = UIView()
        view.backgroundColor = background
        view.layer.cornerRadius = radius
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
        return view
    }
    static func icon(_ symbol: String, color: UIColor = green, size: CGFloat = 22) -> UIImageView {
        let image = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .medium)))
        image.tintColor = color
        image.contentMode = .scaleAspectFit
        image.setContentHuggingPriority(.required, for: .horizontal)
        return image
    }
    static func avatar(_ name: String, color: UIColor = lime, image: UIImage? = nil, size: CGFloat = 46) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: size), view.heightAnchor.constraint(equalToConstant: size)])
        if let image {
            let photo = UIImageView(image: image)
            photo.contentMode = .scaleAspectFill
            photo.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.addSubview(photo)
        } else {
            let initials = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
            let label = label(initials.uppercased(), size: size * 0.31, weight: .bold)
            label.textAlignment = .center
            label.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.addSubview(label)
        }
        view.isAccessibilityElement = true
        view.accessibilityLabel = name
        return view
    }
    static func row(_ leading: UIView, _ trailing: UIView) -> UIStackView {
        let spacer = UIView()
        let row = stack([leading, spacer, trailing], axis: .horizontal, spacing: 10)
        row.alignment = .center
        leading.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

/// Les scènes et la navigation sont déclarées dans Main.storyboard.
/// Les composants communs sont assemblés ici avec Auto Layout.
class LazzyScreenController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LazzyTheme.background
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        contentStack.spacing = 24
    }
    func heading(_ eyebrow: String, title: String, subtitle: String) {
        let stack = LazzyTheme.stack([
            LazzyTheme.label(eyebrow.uppercased(), size: 11, weight: .bold, color: LazzyTheme.orange),
            LazzyTheme.label(title, size: 34, weight: .bold),
            LazzyTheme.label(subtitle, size: 14, color: LazzyTheme.muted)
        ], spacing: 7)
        contentStack.addArrangedSubview(stack)
    }
    func message(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Compris", style: .default))
        present(alert, animated: true)
    }
}
