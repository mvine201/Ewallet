//
//  TransferResultViewController.swift
//  Student eWallet
//
//  Created by Assistant on 30/4/26.
//

import UIKit

final class TransferResultViewController: UIViewController {

    private let draft: TransferDraft

    init(draft: TransferDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.hidesBackButton = true
        setupLayout()
    }

    private func setupLayout() {
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 76).isActive = true

        let statusLabel = UILabel()
        statusLabel.text = "Chuyển tiền thành công"
        statusLabel.font = .systemFont(ofSize: 22, weight: .bold)
        statusLabel.textAlignment = .center

        let amountLabel = UILabel()
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.amount) VND"
        amountLabel.font = .systemFont(ofSize: 30, weight: .bold)
        amountLabel.textAlignment = .center

        let infoCard = makeInfoCard()

        let continueButton = makeSecondaryButton(title: "Tiếp tục chuyển")
        continueButton.addTarget(self, action: #selector(tapContinueTransfer), for: .touchUpInside)

        let homeButton = makePrimaryButton(title: "Quay về trang chủ")
        homeButton.addTarget(self, action: #selector(tapHome), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [continueButton, homeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [iconView, statusLabel, amountLabel, infoCard, buttonStack])
        stack.axis = .vertical
        stack.spacing = 18
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
            makeRow(title: "Người nhận", value: draft.receiver.fullName),
            makeRow(title: "Số điện thoại", value: draft.receiver.phone),
            makeRow(title: "Nội dung", value: draft.description),
            makeRow(title: "Thời gian", value: Self.timeFormatter.string(from: Date()))
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

    @objc private func tapContinueTransfer() {
        guard let navigationController else { return }
        let walletRoot = navigationController.viewControllers.first { $0 is WalletViewController } ?? WalletViewController()
        navigationController.setViewControllers([walletRoot, TransferViewController()], animated: true)
    }

    @objc private func tapHome() {
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
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
