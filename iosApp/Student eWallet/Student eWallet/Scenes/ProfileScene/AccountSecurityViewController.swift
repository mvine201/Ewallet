//
//  AccountSecurityViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class AccountSecurityViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bảo mật tài khoản"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quản lý thông tin xác thực và các lớp bảo vệ cho ví sinh viên của bạn."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bảo mật"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let headerStack = UIStackView(arrangedSubviews: [headerTitleLabel, headerSubtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 4, right: 0)

        let actionStack = UIStackView(arrangedSubviews: [
            makeSecurityButton(
                title: "Thay đổi mật khẩu",
                subtitle: "Cập nhật mật khẩu đăng nhập tài khoản",
                systemImage: "key.fill",
                action: #selector(tapChangePassword)
            ),
            makeSecurityButton(
                title: "Xác thực sinh viên",
                subtitle: "Liên kết mã số sinh viên để mở khóa đầy đủ tính năng",
                systemImage: "person.text.rectangle.fill",
                action: #selector(tapVerifyStudent)
            ),
            makeSecurityButton(
                title: "Quản lý mã PIN",
                subtitle: "Tạo mới hoặc đổi mã PIN dùng khi chuyển tiền và thanh toán",
                systemImage: "number.square.fill",
                action: #selector(tapManagePin)
            )
        ])
        actionStack.axis = .vertical
        actionStack.spacing = 12

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(actionStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeSecurityButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: Selector
    ) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.subtitle = subtitle
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePadding = 14
        configuration.titlePadding = 4
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .semibold)
            return outgoing
        }
        configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .regular)
            outgoing.foregroundColor = .secondaryLabel
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

    @objc private func tapChangePassword() {
        let alert = UIAlertController(title: "Thay đổi mật khẩu", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Mật khẩu hiện tại"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Mật khẩu mới"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Nhập lại mật khẩu mới"
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let currentPassword = alert?.textFields?[0].text ?? ""
            let newPassword = alert?.textFields?[1].text ?? ""
            let confirmPassword = alert?.textFields?[2].text ?? ""
            self.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
        })
        present(alert, animated: true)
    }

    @objc private func tapVerifyStudent() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let user = try await AuthService.shared.getMe()
                await MainActor.run {
                    if user.isVerified {
                        self.showMessage(title: "Xác thực sinh viên", message: "Tài khoản của bạn đã được xác thực sinh viên.")
                    } else {
                        let viewController = StudentVerificationViewController()
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func tapManagePin() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let wallet = try await AuthService.shared.getMyWallet()
                await MainActor.run {
                    if wallet.hasPin {
                        self.showChangePinForm()
                    } else {
                        self.showCreatePinForm()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func showCreatePinForm() {
        let alert = UIAlertController(
            title: "Tạo mã PIN",
            message: "Mã PIN gồm đúng 6 chữ số.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Nhập PIN"
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Nhập lại PIN"
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tạo PIN", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let pin = alert?.textFields?[0].text ?? ""
            let confirmPin = alert?.textFields?[1].text ?? ""
            self.createPin(pin: pin, confirmPin: confirmPin)
        })
        present(alert, animated: true)
    }

    private func showChangePinForm() {
        let alert = UIAlertController(
            title: "Thay đổi mã PIN",
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "PIN hiện tại"
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "PIN mới gồm 6 chữ số"
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }
        alert.addTextField { textField in
            textField.placeholder = "Nhập lại PIN mới"
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let currentPin = alert?.textFields?[0].text ?? ""
            let pin = alert?.textFields?[1].text ?? ""
            let confirmPin = alert?.textFields?[2].text ?? ""
            self.changePin(currentPin: currentPin, pin: pin, confirmPin: confirmPin)
        })
        present(alert, animated: true)
    }

    private func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            showMessage(title: "Lỗi", message: "Vui lòng nhập đầy đủ thông tin")
            return
        }

        guard newPassword.count >= 6 else {
            showMessage(title: "Lỗi", message: "Mật khẩu mới phải có ít nhất 6 ký tự")
            return
        }

        guard newPassword == confirmPassword else {
            showMessage(title: "Lỗi", message: "Mật khẩu mới nhập lại không khớp")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await AuthService.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                await MainActor.run {
                    self.showMessage(title: "Thành công", message: message)
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func createPin(pin: String, confirmPin: String) {
        let trimmedPin = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirmPin = confirmPin.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedPin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            showMessage(title: "Lỗi", message: "PIN phải gồm đúng 6 chữ số")
            return
        }

        guard trimmedPin == trimmedConfirmPin else {
            showMessage(title: "Lỗi", message: "PIN nhập lại không khớp")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await AuthService.shared.changePin(currentPin: nil, pin: trimmedPin)
                await MainActor.run {
                    self.showMessage(title: "Thành công", message: message)
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func changePin(currentPin: String, pin: String, confirmPin: String) {
        let trimmedCurrentPin = currentPin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPin = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirmPin = confirmPin.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedCurrentPin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            showMessage(title: "Lỗi", message: "PIN hiện tại phải gồm đúng 6 chữ số")
            return
        }

        guard trimmedPin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            showMessage(title: "Lỗi", message: "PIN mới phải gồm đúng 6 chữ số")
            return
        }

        guard trimmedPin == trimmedConfirmPin else {
            showMessage(title: "Lỗi", message: "PIN mới nhập lại không khớp")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await AuthService.shared.changePin(currentPin: trimmedCurrentPin, pin: trimmedPin)
                await MainActor.run {
                    self.showMessage(title: "Thành công", message: message)
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
