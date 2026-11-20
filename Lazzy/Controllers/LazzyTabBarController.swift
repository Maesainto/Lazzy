import UIKit

final class LazzyTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = LazzyTheme.green
        // Palette constante : le décor de pierre et les cartes sont pensés pour ce thème clair.
        overrideUserInterfaceStyle = .light
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = LazzyTheme.background
        appearance.shadowColor = LazzyTheme.line
        for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            item.normal.iconColor = LazzyTheme.muted
            item.normal.titleTextAttributes = [.foregroundColor: LazzyTheme.muted, .font: LazzyTheme.font(10, .medium)]
            item.selected.iconColor = LazzyTheme.green
            item.selected.titleTextAttributes = [.foregroundColor: LazzyTheme.green, .font: LazzyTheme.font(10, .bold)]
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        let tabs = [("house", "house.fill", "tab.home"),
                    ("square.grid.2x2", "square.grid.2x2.fill", "tab.wall"),
                    ("person.2", "person.2.fill", "tab.groups")]
        for (controller, (symbol, selectedSymbol, identifier)) in zip(viewControllers ?? [], tabs) {
            controller.tabBarItem.image = UIImage(systemName: symbol)
            controller.tabBarItem.selectedImage = UIImage(systemName: selectedSymbol)
            controller.tabBarItem.accessibilityIdentifier = identifier
        }
    }
}
