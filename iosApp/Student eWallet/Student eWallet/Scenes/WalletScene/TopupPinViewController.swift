//
//  TopupPinViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class TopupPinViewController: UIViewController {

    private let draft: TopupDraft
    private let pinField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Nhập mã PIN"
        textField.keyboardType = .numberPad
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 22, weight: .semibold)
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return textField
    }()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(draft: TopupDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Xác nhận PIN"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "Nhập mã PIN"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Nhập PIN ví để xác nhận tạo giao dịch nạp tiền qua VNPay."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Mở VNPay", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: #selector(tapOpenPayment), for: .touchUpInside)

        activity.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, pinField, button, activity])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func tapOpenPayment() {
        view.endEditing(true)
        let pin = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard pin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            showMessage(title: "Lỗi", message: "PIN phải gồm đúng 6 chữ số")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let topup = try await WalletService.shared.createTopup(amount: self.draft.amount, pin: pin)
                await MainActor.run {
                    self.setLoading(false)
                    self.openPayment(topup)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func openPayment(_ topup: TopupData) {
        if let url = URL(string: topup.paymentUrl) {
            UIApplication.shared.open(url)
        }

        let waitingViewController = TopupWaitingViewController(
            amount: draft.amount,
            orderId: topup.orderId,
            paymentUrl: topup.paymentUrl
        )
        navigationController?.pushViewController(waitingViewController, animated: true)
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
