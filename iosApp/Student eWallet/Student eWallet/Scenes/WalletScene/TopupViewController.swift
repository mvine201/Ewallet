//
//  TopupViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

struct TopupDraft {
    let amount: Double
}

final class TopupViewController: UIViewController, UITextFieldDelegate {

    private let amountField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Số tiền nạp"
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nạp tiền"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "Nạp tiền vào ví"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Nhập số tiền bạn muốn nạp vào ví."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Tiếp tục", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, amountField, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    @objc private func tapContinue() {
        view.endEditing(true)
        let amountText = amountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let amount = Double(amountText), amount >= 10000 else {
            showMessage(title: "Lỗi", message: "Số tiền nạp tối thiểu là 10,000 VND")
            return
        }

        let confirmViewController = TopupConfirmViewController(draft: TopupDraft(amount: amount))
        navigationController?.pushViewController(confirmViewController, animated: true)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
