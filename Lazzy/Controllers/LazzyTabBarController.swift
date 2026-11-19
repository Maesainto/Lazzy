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
        let symbols = [("house", "house.fill"), ("square.grid.2x2", "square.grid.2x2.fill"),
                       ("person.2", "person.2.fill"), ("slider.horizontal.3", "slider.horizontal.3")]
        for (index, controller) in (viewControllers ?? []).enumerated() {
            controller.tabBarItem.image = UIImage(systemName: symbols[index].0)
            controller.tabBarItem.selectedImage = UIImage(systemName: symbols[index].1)
            controller.tabBarItem.accessibilityIdentifier = ["tab.home", "tab.wall", "tab.groups", "tab.settings"][index]
        }
    }
}
