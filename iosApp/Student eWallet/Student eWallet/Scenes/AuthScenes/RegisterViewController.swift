//  RegisterViewController.swift
//  Student eWallet
//
//  Created by Assistant on 13/4/26.
//

import UIKit

final class RegisterViewController: UIViewController {

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Đăng ký"
        lb.font = .systemFont(ofSize: 28, weight: .bold)
        lb.textAlignment = .center
        lb.textColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
        return lb
    }()

    private let fullNameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Họ và tên"
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        return tf
    }()

    private let phoneField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Số điện thoại"
        tf.keyboardType = .phonePad
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        return tf
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email (không bắt buộc)"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.borderStyle = .roundedRect
        return tf
    }()

    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Mật khẩu (>= 6 ký tự)"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        return tf
    }()

    private let registerButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Tạo tài khoản", for: .normal)
        bt.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        bt.tintColor = .white
        bt.layer.cornerRadius = 10
        bt.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return bt
    }()

    private let activity = UIActivityIndicatorView(style: .medium)

    var onRegisterSuccess: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        setupLayout()
        enableKeyboardDismissOnTap()
        registerButton.addTarget(self, action: #selector(tapRegister), for: .touchUpInside)
        navigationItem.backButtonTitle = ""
    }

    private func setupLayout() {
        // Use a scroll view to ensure content is visible on small screens and when keyboard appears
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let stack = UIStackView(arrangedSubviews: [titleLabel, fullNameField, phoneField, emailField, passwordField, registerButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        contentView.addSubview(activity)

        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // ScrollView pinning
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            // ContentView inside scrollView
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Match contentView width to scrollView frame width for vertical scrolling
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Stack constraints
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),

            // Activity indicator under the stack, defines the bottom of content
            activity.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activity.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            activity.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        // Ensure text fields have a reasonable height
        [fullNameField, phoneField, emailField, passwordField].forEach { field in
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        }

        // Give the title a bit of bottom spacing visually
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    @objc private func tapRegister() {
        view.endEditing(true)

        let fullName = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let emailText = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailText.isEmpty ? nil : emailText
        let password = passwordField.text ?? ""

        // Basic validations to avoid unnecessary server calls
        if fullName.isEmpty {
            showError("Vui lòng nhập họ và tên")
            return
        }
        if phone.isEmpty {
            showError("Vui lòng nhập số điện thoại")
            return
        }
        if password.count < 6 {
            showError("Mật khẩu phải có ít nhất 6 ký tự")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.register(fullName: fullName, phone: phone, password: password, email: email)
                await MainActor.run {
                    self.setLoading(false)
                    let alert = UIAlertController(title: "Thành công", message: "Đăng ký thành công. Vui lòng đăng nhập.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.onRegisterSuccess?()
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        registerButton.isEnabled = !loading
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
