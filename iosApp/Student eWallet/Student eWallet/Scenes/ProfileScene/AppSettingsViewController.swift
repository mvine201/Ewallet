import UIKit

enum AppPreferences {
    private static let notificationsEnabledKey = "app_notifications_enabled"

    static var notificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey)
            NotificationCenter.default.post(name: .appNotificationPreferenceChanged, object: nil)
        }
    }
}

final class AppSettingsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let notificationSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cài đặt về app"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        applyCurrentPreferences()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(makeNotificationSection())
        contentStack.addArrangedSubview(makeActionButton(
            title: "Thông tin liên hệ tổng đài",
            subtitle: "Xem số điện thoại và email hỗ trợ",
            systemImage: "phone.circle",
            tintColor: .label,
            action: #selector(tapSupportInfo)
        ))
        contentStack.addArrangedSubview(makeActionButton(
            title: "Đăng xuất",
            subtitle: "Thoát khỏi tài khoản hiện tại",
            systemImage: "rectangle.portrait.and.arrow.right",
            tintColor: .systemRed,
            action: #selector(tapLogout)
        ))

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeNotificationSection() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Cài đặt thông báo"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Bật để hiển thị badge đỏ và các thông báo trong ứng dụng."
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged), for: .valueChanged)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [textStack, notificationSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        row.backgroundColor = .secondarySystemGroupedBackground
        row.layer.cornerRadius = 12
        row.layer.masksToBounds = true
        return row
    }

    private func makeActionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tintColor: UIColor,
        action: Selector
    ) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.subtitle = subtitle
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePadding = 14
        configuration.titlePadding = 4
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.baseForegroundColor = tintColor
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .semibold)
            return outgoing
        }
        configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .regular)
            outgoing.foregroundColor = tintColor.withAlphaComponent(0.75)
            return outgoing
        }

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 76).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func applyCurrentPreferences() {
        notificationSwitch.isOn = AppPreferences.notificationsEnabled
    }

    @objc private func notificationSwitchChanged() {
        AppPreferences.notificationsEnabled = notificationSwitch.isOn
    }

    @objc private func tapSupportInfo() {
        let alert = UIAlertController(
            title: "Thông tin liên hệ tổng đài",
            message: "Số điện thoại: 0878016294\nEmail: macvinh92@gmail.com",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }

    @objc private func tapLogout() {
        let alert = UIAlertController(
            title: "Đăng xuất",
            message: "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        TokenStore.shared.clear()

        guard
            let windowScene = view.window?.windowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate
        else {
            return
        }

        let login = LoginViewController()
        let nav = UINavigationController(rootViewController: login)
        login.onLoginSuccess = { [weak sceneDelegate] in
            let main = MainTabBarController()
            sceneDelegate?.window?.rootViewController = main
            sceneDelegate?.window?.makeKeyAndVisible()
        }

        sceneDelegate.window?.rootViewController = nav
        sceneDelegate.window?.makeKeyAndVisible()
    }
}
