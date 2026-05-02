import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabs()
        setupAppearance()
    }


    private func setupTabs() {
        let homeNav = createNav(
            title: "Home",
            image: "house",
            selectedImage: "house.fill",
            root: HomeViewController()
        )
        let walletNav = createNav(
            title: "Wallet",
            image: "creditcard",
            selectedImage: "creditcard.fill",
            root: WalletViewController()
        )
        let historyNav = createNav(
            title: "History",
            image: "clock.arrow.circlepath",
            selectedImage: "clock.arrow.circlepath",
            root: TransactionHistoryViewController()
        )
        let profileNav = createNav(
            title: "Me",
            image: "person",
            selectedImage: "person.fill",
            root: ProfileViewController()
        )

        viewControllers = [homeNav, walletNav, historyNav, profileNav]
        selectedIndex = 0
    }
    

    private func createNav(
        title: String,
        image: String,
        selectedImage: String,
        root: UIViewController
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: UIImage(systemName: selectedImage)
        )
        return nav
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear

        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard
            let navigationController = viewController as? UINavigationController,
            navigationController.viewControllers.first is WalletViewController
        else {
            return
        }

        navigationController.popToRootViewController(animated: false)
    }
}
