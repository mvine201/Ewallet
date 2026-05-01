//
//  TransferViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

struct TransferDraft {
    let receiverQuery: String
    let receiver: ReceiverInfo
    let amount: Double
    let description: String
}

final class TransferViewController: UIViewController, UITextFieldDelegate {

    private var currentUser: AuthUser?
    private var availableBalance: Double?
    private var resolvedReceiver: ReceiverInfo?
    private var lookupTask: Task<Void, Never>?
    private let receiverField = TransferViewController.makeTextField(placeholder: "Số điện thoại hoặc MSSV người nhận")
    private let receiverNameField = TransferViewController.makeTextField(placeholder: "Tên người nhận")
    private let amountField = TransferViewController.makeTextField(placeholder: "Số tiền")
    private let amountErrorLabel = UILabel()
    private let descriptionField = TransferViewController.makeTextField(placeholder: "Nội dung")
    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chuyển tiền"
        view.backgroundColor = .systemGroupedBackground
        setupBackButton()
        setupLayout()
        loadCurrentUser()
    }

    private func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(tapBack)
        )
    }

    private func setupLayout() {
        amountField.keyboardType = .numberPad
        amountField.addTarget(self, action: #selector(amountTextDidChange), for: .editingChanged)
        receiverField.delegate = self
        receiverField.addTarget(self, action: #selector(receiverTextDidChange), for: .editingChanged)

        amountErrorLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        amountErrorLabel.textColor = .systemRed
        amountErrorLabel.numberOfLines = 0
        amountErrorLabel.isHidden = true

        receiverNameField.isEnabled = false
        receiverNameField.text = ""
        receiverNameField.textColor = .secondaryLabel
        receiverNameField.font = .systemFont(ofSize: 15, weight: .semibold)

        let titleLabel = UILabel()
        titleLabel.text = "Chuyển tiền"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Nhập người nhận, số tiền và nội dung chuyển tiền."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let continueButton = makePrimaryButton(title: "Tiếp tục")
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)

        activity.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            receiverField,
            receiverNameField,
            amountField,
            amountErrorLabel,
            descriptionField,
            continueButton,
            activity
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    private func loadCurrentUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                async let userRequest = AuthService.shared.getMe()
                async let walletRequest = AuthService.shared.getMyWallet()
                let (user, wallet) = try await (userRequest, walletRequest)
                await MainActor.run {
                    self.currentUser = user
                    self.availableBalance = wallet.balance
                    self.descriptionField.placeholder = "\(user.fullName) CHUYEN TIEN"
                    _ = self.validateAmount(shouldShowEmpty: false)
                }
            } catch {
                await MainActor.run {
                    self.descriptionField.placeholder = "CHUYEN TIEN"
                }
            }
        }
    }

    @objc private func amountTextDidChange() {
        _ = validateAmount(shouldShowEmpty: false)
    }

    @objc private func tapBack() {
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            tabBarController?.selectedIndex = 1
        }
    }

    @objc private func receiverTextDidChange() {
        resolvedReceiver = nil
        let query = receiverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        lookupTask?.cancel()

        guard !query.isEmpty else {
            receiverNameField.text = ""
            receiverNameField.textColor = .secondaryLabel
            return
        }

        receiverNameField.text = "ĐANG TÌM..."
        receiverNameField.textColor = .secondaryLabel

        lookupTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, let self else { return }

            do {
                let receiver = try await TransactionService.shared.lookupReceiver(query: query)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.resolvedReceiver = receiver
                    self.receiverNameField.text = Self.normalizedDisplayName(receiver.fullName)
                    self.receiverNameField.textColor = .label
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.resolvedReceiver = nil
                    self.receiverNameField.text = "KHÔNG CÓ NGƯỜI DÙNG NÀY"
                    self.receiverNameField.textColor = .systemRed
                }
            }
        }
    }

    private func makePrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }

    @objc private func tapContinue() {
        view.endEditing(true)

        let receiverQuery = receiverField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let customDescription = descriptionField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !receiverQuery.isEmpty else {
            showMessage(title: "Lỗi", message: "Vui lòng nhập số điện thoại hoặc MSSV người nhận")
            return
        }

        guard let amount = validateAmount(shouldShowEmpty: true) else {
            return
        }

        let defaultDescription = "\(currentUser?.fullName ?? "") CHUYEN TIEN".trimmingCharacters(in: .whitespacesAndNewlines)
        let description = customDescription.isEmpty ? (defaultDescription.isEmpty ? "CHUYEN TIEN" : defaultDescription) : customDescription

        guard let receiver = resolvedReceiver else {
            showMessage(title: "Lỗi", message: "Không tìm thấy người nhận hợp lệ")
            return
        }

        let draft = TransferDraft(
            receiverQuery: receiverQuery,
            receiver: receiver,
            amount: amount,
            description: description
        )
        navigationController?.pushViewController(
            TransferConfirmViewController(draft: draft),
            animated: true
        )
    }

    private func validateAmount(shouldShowEmpty: Bool) -> Double? {
        let amountText = amountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !amountText.isEmpty else {
            setAmountError(shouldShowEmpty ? "Vui lòng nhập số tiền" : nil)
            return nil
        }

        guard let amount = Self.parseAmount(amountText) else {
            setAmountError("Số tiền sai định dạng")
            return nil
        }

        guard amount >= 1000 else {
            setAmountError("Số tiền tối thiểu là 1.000đ")
            return nil
        }

        if let availableBalance, amount > availableBalance {
            setAmountError("Số dư không đủ")
            return nil
        }

        setAmountError(nil)
        return amount
    }

    private func setAmountError(_ message: String?) {
        if let message {
            amountErrorLabel.text = "* \(message)"
            amountErrorLabel.isHidden = false
        } else {
            amountErrorLabel.text = nil
            amountErrorLabel.isHidden = true
        }
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static func makeTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return textField
    }

    private static func normalizedDisplayName(_ name: String) -> String {
        name
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .uppercased()
    }

    private static func parseAmount(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else {
            return nil
        }

        if cleaned.allSatisfy({ $0.isNumber }) {
            return Double(cleaned)
        }

        let hasDot = cleaned.contains(".")
        let hasComma = cleaned.contains(",")

        guard hasDot != hasComma else {
            return nil
        }

        let separator: Character = hasDot ? "." : ","
        let parts = cleaned.split(separator: separator, omittingEmptySubsequences: false)

        guard parts.count > 1,
              (1...3).contains(parts[0].count),
              parts[0].allSatisfy({ $0.isNumber }),
              parts.dropFirst().allSatisfy({ $0.count == 3 && $0.allSatisfy { $0.isNumber } }) else {
            return nil
        }

        return Double(parts.joined())
    }
}
