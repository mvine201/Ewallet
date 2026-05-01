//
//  TransferConfirmViewController.swift
//  Student eWallet
//
//  Created by Assistant on 30/4/26.
//

import UIKit

final class TransferConfirmViewController: UIViewController {

    private let draft: TransferDraft
    private let dimView = UIView()
    private let pinSheet = UIView()
    private let pinField = UITextField()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(draft: TransferDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chuyển tiền"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        setupPinSheet()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "Chuyển tiền"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.numberOfLines = 0

        let infoCard = makeInfoCard()
        let confirmButton = makePrimaryButton(title: "Xác nhận")
        confirmButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, infoCard, confirmButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    private func makeInfoCard() -> UIView {
        let stack = UIStackView(arrangedSubviews: [
            makeRow(title: "SĐT/MSSV người nhận", value: draft.receiverQuery),
            makeRow(title: "Tên người nhận", value: draft.receiver.fullName),
            makeRow(title: "Số điện thoại", value: draft.receiver.phone),
            makeRow(title: "Số tiền", value: Self.currencyFormatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.amount) VND"),
            makeRow(title: "Nội dung", value: draft.description)
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
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

    private func setupPinSheet() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(hidePinSheet))
        dimView.addGestureRecognizer(tap)

        pinSheet.backgroundColor = .systemBackground
        pinSheet.layer.cornerRadius = 18
        pinSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pinSheet.transform = CGAffineTransform(translationX: 0, y: 320)
        pinSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinSheet)

        let titleLabel = UILabel()
        titleLabel.text = "Nhập mã PIN"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        pinField.placeholder = "PIN ví"
        pinField.keyboardType = .numberPad
        pinField.isSecureTextEntry = true
        pinField.textAlignment = .center
        pinField.font = .systemFont(ofSize: 22, weight: .semibold)
        pinField.borderStyle = .roundedRect
        pinField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let confirmButton = makePrimaryButton(title: "Xác nhận chuyển")
        confirmButton.addTarget(self, action: #selector(tapSubmitPin), for: .touchUpInside)

        activity.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, pinField, confirmButton, activity])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        pinSheet.addSubview(stack)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pinSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinSheet.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.leadingAnchor.constraint(equalTo: pinSheet.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: pinSheet.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: pinSheet.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: pinSheet.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    @objc private func tapConfirm() {
        showPinSheet()
    }

    private func showPinSheet() {
        pinField.text = nil
        UIView.animate(withDuration: 0.25) {
            self.dimView.alpha = 1
            self.pinSheet.transform = .identity
        } completion: { _ in
            self.pinField.becomeFirstResponder()
        }
    }

    @objc private func hidePinSheet() {
        view.endEditing(true)
        UIView.animate(withDuration: 0.25) {
            self.dimView.alpha = 0
            self.pinSheet.transform = CGAffineTransform(translationX: 0, y: 320)
        }
    }

    @objc private func tapSubmitPin() {
        let pin = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard pin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            showMessage(title: "Lỗi", message: "PIN phải gồm đúng 6 chữ số")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await TransactionService.shared.transfer(
                    receiverId: self.draft.receiver.id,
                    amount: self.draft.amount,
                    description: self.draft.description,
                    pin: pin
                )
                await MainActor.run {
                    self.setLoading(false)
                    self.hidePinSheet()
                    self.navigationController?.pushViewController(
                        TransferResultViewController(draft: self.draft),
                        animated: true
                    )
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        view.isUserInteractionEnabled = !loading
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()
}
