import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let notificationTabIndex = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabs()
        setupAppearance()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotificationBadge),
            name: .notificationsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotificationBadge),
            name: .appNotificationPreferenceChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotificationBadge),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        refreshNotificationBadge()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    private func setupTabs() {
        let homeNav = createNav(
            title: "Home",
            image: "house",
            selectedImage: "house.fill",
            root: HomeViewController()
        )
        let historyNav = createNav(
            title: "History",
            image: "clock.arrow.circlepath",
            selectedImage: "clock.arrow.circlepath",
            root: TransactionHistoryViewController()
        )
        let notiNav = createNav(
            title: "Notifications",
            image: "bell",
            selectedImage: "bell",
            root: NotificationViewController()
        )
        let profileNav = createNav(
            title: "Me",
            image: "person",
            selectedImage: "person.fill",
            root: ProfileViewController()
        )

        viewControllers = [homeNav, historyNav, notiNav, profileNav]
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

    @objc private func refreshNotificationBadge() {
        guard AppPreferences.notificationsEnabled else {
            viewControllers?[notificationTabIndex].tabBarItem.badgeValue = nil
            return
        }

        Task { [weak self] in
            guard
                let self,
                let token = TokenStore.shared.token
            else { return }

            do {
                let request = try APIEndpoint.getNotifications.urlRequest(token: token)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                let decoder = JSONDecoder()
                let result = try decoder.decode(NotificationResponse.self, from: data)
                let unreadCount = result.data.filter { !$0.isRead }.count

                await MainActor.run {
                    guard self.viewControllers?.indices.contains(self.notificationTabIndex) == true else { return }
                    self.viewControllers?[self.notificationTabIndex].tabBarItem.badgeValue = unreadCount > 0 ? String(unreadCount) : nil
                    self.viewControllers?[self.notificationTabIndex].tabBarItem.badgeColor = .systemRed
                }
            } catch {
                await MainActor.run {
                    guard self.viewControllers?.indices.contains(self.notificationTabIndex) == true else { return }
                    self.viewControllers?[self.notificationTabIndex].tabBarItem.badgeValue = nil
                }
            }
        }
    }
}
