//
//  TopupResultViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class TopupResultViewController: UIViewController {

    private let amount: Double
    private let orderId: String
    private let paymentUrl: String

    init(amount: Double, orderId: String, paymentUrl: String) {
        self.amount = amount
        self.orderId = orderId
        self.paymentUrl = paymentUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Kết quả giao dịch"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let statusLabel = UILabel()
        statusLabel.text = "Giao dịch thành công"
        statusLabel.font = .systemFont(ofSize: 20, weight: .bold)
        statusLabel.textAlignment = .center

        let amountLabel = UILabel()
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) VND"
        amountLabel.font = .systemFont(ofSize: 28, weight: .bold)
        amountLabel.textAlignment = .center

        let noteLabel = UILabel()
        noteLabel.text = "Giao dịch thành công, vui lòng kiểm tra số dư và lịch sử giao dịch!"
        noteLabel.font = .systemFont(ofSize: 14)
        noteLabel.textColor = .secondaryLabel
        noteLabel.textAlignment = .center
        noteLabel.numberOfLines = 0

        let infoCard = makeInfoCard()

        let retryButton = makeSecondaryButton(title: "Mở lại VNPay")
        retryButton.addTarget(self, action: #selector(tapOpenAgain), for: .touchUpInside)

        let homeButton = makePrimaryButton(title: "Màn hình chính")
        homeButton.addTarget(self, action: #selector(tapHome), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [retryButton, homeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [iconView, statusLabel, amountLabel, noteLabel, infoCard, buttonStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])
    }

    private func makeInfoCard() -> UIView {
        let stack = UIStackView(arrangedSubviews: [
            makeRow(title: "Dịch vụ", value: "Nạp tiền vào ví"),
            makeRow(title: "Mã giao dịch", value: orderId),
            makeRow(title: "Thời gian tạo", value: Self.timeFormatter.string(from: Date()))
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

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
    }

    private func makePrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    private func makeSecondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    @objc private func tapOpenAgain() {
        if let url = URL(string: paymentUrl) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func tapHome() {
        navigationController?.popToRootViewController(animated: true)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - dd/MM/yyyy"
        return formatter
    }()
}
