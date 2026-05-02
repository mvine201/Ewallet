//
//  ProfileViewController.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 10/4/26.
//

import UIKit

final class ProfileViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let avatarView: UILabel = {
        let label = UILabel()
        label.text = "?"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        label.layer.cornerRadius = 36
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Đang tải..."
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .right
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let verifiedIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tài Khoản"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadProfile()
    }
    override func viewWillAppear(_ animated: Bool) {
        loadProfile()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, verifiedIconView])
        nameStack.axis = .horizontal
        nameStack.spacing = 6
        nameStack.alignment = .center
        nameStack.distribution = .fill

        let headerStack = UIStackView(arrangedSubviews: [avatarView, nameStack, phoneLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 10
        headerStack.alignment = .center
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 28, left: 20, bottom: 18, right: 20)

        activity.hidesWhenStopped = true

        let actionStack = UIStackView(arrangedSubviews: [
            makeActionButton(title: "Thông tin tài khoản", systemImage: "person.text.rectangle", action: #selector(tapAccountInfo)),
            makeActionButton(title: "Bảo mật tài khoản", systemImage: "lock.shield", action: #selector(tapSecurity)),
            makeActionButton(title: "Cài đặt", systemImage: "gearshape", action: #selector(tapAppSettings))
        ])
        actionStack.axis = .vertical
        actionStack.spacing = 12

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(actionStack)
        contentStack.addArrangedSubview(activity)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),
            verifiedIconView.widthAnchor.constraint(equalToConstant: 20),
            verifiedIconView.heightAnchor.constraint(equalToConstant: 20),
            nameStack.leadingAnchor.constraint(greaterThanOrEqualTo: contentStack.leadingAnchor),
            nameStack.trailingAnchor.constraint(lessThanOrEqualTo: contentStack.trailingAnchor)
        ])
    }

    private func makeActionButton(title: String, systemImage: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePadding = 12
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func loadProfile() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let user = try await AuthService.shared.getMe()
                await MainActor.run {
                    self.setLoading(false)
                    self.apply(user: user)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func apply(user: AuthUser) {
        nameLabel.text = user.fullName
        phoneLabel.text = user.phone
        avatarView.text = initials(from: user.fullName)
        verifiedIconView.tintColor = user.isVerified ? .systemGreen : .systemGray3
    }

    private func initials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .compactMap { $0.first }

        if parts.count == 1, let first = parts.first {
            return String(first).uppercased()
        }

        if let first = parts.first, let last = parts.last {
            return String([first, last]).uppercased()
        }

        return String(name.prefix(1)).uppercased()
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    @objc private func tapAccountInfo() {
        let accountInfoViewController = AccountInfoViewController()
        navigationController?.pushViewController(accountInfoViewController, animated: true)
    }

    @objc private func tapSecurity() {
        let securityViewController = AccountSecurityViewController()
        navigationController?.pushViewController(securityViewController, animated: true)
    }

    @objc private func tapAppSettings() {
        let appSettingsViewController = AppSettingsViewController()
        navigationController?.pushViewController(appSettingsViewController, animated: true)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
