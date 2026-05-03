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
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        setupLayout()
    }

    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let statusLabel = UILabel()
        statusLabel.text = "Chuyển tiền thành công"
        statusLabel.font = .systemFont(ofSize: 24, weight: .bold)
        statusLabel.textAlignment = .center

        let amountLabel = UILabel()
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.amount) VND"
        amountLabel.font = .systemFont(ofSize: 34, weight: .bold)
        amountLabel.textAlignment = .center
        amountLabel.textColor = .label

        let infoCard = makeInfoCard()

        let continueButton = makeSecondaryButton(title: "Tiếp tục chuyển")
        continueButton.addTarget(self, action: #selector(tapContinueTransfer), for: .touchUpInside)

        let homeButton = makePrimaryButton(title: "Quay về trang chủ")
        homeButton.addTarget(self, action: #selector(tapHome), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [continueButton, homeButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 14

        let resultCard = UIView()
        resultCard.applyAppCardStyle()

        let stack = UIStackView(arrangedSubviews: [iconView, statusLabel, amountLabel, infoCard, buttonStack])
        stack.axis = .vertical
        stack.spacing = 24
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 32, left: 24, bottom: 32, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(stack)

        view.addSubview(scrollView)
        scrollView.addSubview(resultCard)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            resultCard.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            resultCard.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            resultCard.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            resultCard.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            resultCard.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            
            stack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: resultCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor)
        ])
        
        // Subtle entrance animation
        resultCard.alpha = 0
        resultCard.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut) {
            resultCard.alpha = 1
            resultCard.transform = .identity
        }
    }

    private func makeInfoCard() -> UIView {
        let card = UIView()
        card.applyInfoCardStyle()
        
        let stack = UIStackView(arrangedSubviews: [
            makeRow(title: "Người nhận", value: draft.receiver.fullName),
            makeRow(title: "Số điện thoại", value: draft.receiver.phone),
            makeRow(title: "Nội dung", value: draft.description),
            makeRow(title: "Thời gian", value: Self.timeFormatter.string(from: Date()))
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
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
        button.applyPrimaryAppStyle()
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    private func makeSecondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.applySecondaryAppStyle()
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    @objc private func tapContinueTransfer() {
        guard let navigationController else { return }
        let walletRoot = navigationController.viewControllers.first { $0 is WalletViewController } ?? WalletViewController()
        navigationController.setViewControllers([walletRoot, TransferViewController()], animated: true)
    }

    @objc private func tapHome() {
        redirectToHomeTab()
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
