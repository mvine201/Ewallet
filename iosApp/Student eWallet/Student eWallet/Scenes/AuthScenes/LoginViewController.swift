//
//  LoginViewController.swift
//  Student eWallet
//
//  Updated by Assistant on 13/4/26
//

import UIKit

final class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI
    private lazy var brandHeaderView: UIView = makeBrandHeaderView()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Đăng nhập"
        lb.font = .systemFont(ofSize: 28, weight: .bold)
        lb.textAlignment = .center
        lb.textColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
        return lb
    }()

    private let phoneField: UITextField = LoginViewController.makeTextField(
        placeholder: "Số điện thoại",
        keyboard: .phonePad,
        isSecure: false
    )

    private let passwordField: UITextField = LoginViewController.makeTextField(
        placeholder: "Mật khẩu",
        keyboard: .default,
        isSecure: true
    )

    private let passwordToggleButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Hiện", for: .normal)
        bt.setTitleColor(UIColor.systemBlue, for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        bt.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return bt
    }()

    private let loginButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Đăng nhập", for: .normal)
        bt.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        bt.tintColor = .white
        bt.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        bt.layer.cornerRadius = 10
        bt.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return bt
    }()

    private let goRegisterButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Chưa có tài khoản? Đăng ký", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        bt.setTitleColor(UIColor(red: 0.8, green: 0, blue: 0, alpha: 1), for: .normal)
        bt.backgroundColor = UIColor.systemBackground
        bt.layer.cornerRadius = 10
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1).cgColor
        bt.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        bt.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return bt
    }()

    private let forgotPasswordButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Quên mật khẩu?", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        bt.setTitleColor(UIColor(red: 0.8, green: 0, blue: 0, alpha: 1), for: .normal)
        bt.backgroundColor = UIColor.systemBackground
        bt.layer.cornerRadius = 10
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1).cgColor
        bt.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        bt.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return bt
    }()

    private let activity = UIActivityIndicatorView(style: .medium)

    // Callback để SceneDelegate chuyển root khi login thành công
    var onLoginSuccess: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()
        setupBehaviors()
        navigationItem.backButtonTitle = ""
    }

    // MARK: - Setup
    private func setupLayout() {
        // Ensure text fields have visible height
        phoneField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Password right view (show/hide)
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: 44))
        passwordToggleButton.frame = rightContainer.bounds
        rightContainer.addSubview(passwordToggleButton)
        passwordField.rightView = rightContainer
        passwordField.rightViewMode = .always

        let stack = UIStackView(arrangedSubviews: [
            brandHeaderView,
            titleLabel,
            phoneField,
            passwordField,
            loginButton,
            goRegisterButton,
            forgotPasswordButton
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(18, after: brandHeaderView)
        stack.setCustomSpacing(16, after: titleLabel)
        stack.setCustomSpacing(6, after: goRegisterButton)

        activity.hidesWhenStopped = true

        view.addSubview(stack)
        view.addSubview(activity)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16)
        ])
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)
        goRegisterButton.addTarget(self, action: #selector(tapGoRegister), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(tapForgotPassword), for: .touchUpInside)
    }

    private func setupBehaviors() {
        phoneField.delegate = self
        passwordField.delegate = self
        phoneField.returnKeyType = .next
        passwordField.returnKeyType = .done

        // Dismiss keyboard when tapping outside
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Actions
    @objc private func tapGoRegister() {
        let vc = RegisterViewController()
        vc.onRegisterSuccess = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            // hoặc self?.dismiss(animated: true) nếu present
        }
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }

    @objc private func tapForgotPassword() {
        let alert = UIAlertController(
            title: "Quên mật khẩu",
            message: "liên hệ 0878016294 để được hỗ trợ",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func tapLogin() {
        view.endEditing(true)

        // Basic validation
        let phone = phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        guard !phone.isEmpty else {
            showError("Vui lòng nhập số điện thoại")
            return
        }
        guard !password.isEmpty else {
            showError("Vui lòng nhập mật khẩu")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.login(phone: phone, password: password)
                await MainActor.run {
                    self.setLoading(false)
                    self.onLoginSuccess?()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        // Maintain cursor position when toggling secure entry
        if let existingText = passwordField.text, passwordField.isFirstResponder {
            passwordField.deleteBackward()
            passwordField.insertText(existingText + " ")
            passwordField.deleteBackward()
        }
        let title = passwordField.isSecureTextEntry ? "Hiện" : "Ẩn"
        passwordToggleButton.setTitle(title, for: .normal)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Helpers
    private func setLoading(_ loading: Bool) {
        loginButton.isEnabled = !loading
        loginButton.alpha = loading ? 0.6 : 1.0
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeBrandHeaderView() -> UIView {
        let logoContainer = UIView()
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.08)
        logoContainer.layer.cornerRadius = 34
        logoContainer.layer.cornerCurve = .continuous

        let logoView = UIImageView(image: UIImage(named: "LogoUniEwallet_xoanen"))
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFit

        let appNameLabel = UILabel()
        appNameLabel.text = "Uni Ewallet"
        appNameLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        appNameLabel.textColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
        appNameLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Ví sinh viên cho thanh toán dịch vụ trường học"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        logoContainer.addSubview(logoView)

        let stack = UIStackView(arrangedSubviews: [logoContainer, appNameLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            logoContainer.widthAnchor.constraint(equalToConstant: 92),
            logoContainer.heightAnchor.constraint(equalToConstant: 92),

            logoView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 70),
            logoView.heightAnchor.constraint(equalToConstant: 70),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === phoneField {
            passwordField.becomeFirstResponder()
        } else if textField === passwordField {
            tapLogin()
        }
        return true
    }

    // MARK: - Factory
    private static func makeTextField(placeholder: String, keyboard: UIKeyboardType, isSecure: Bool) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboard
        tf.isSecureTextEntry = isSecure
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        // Padding left/right via views
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        let right = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        tf.leftView = left
        tf.leftViewMode = .always
        tf.rightView = right
        tf.rightViewMode = .unlessEditing
        return tf
    }
}
