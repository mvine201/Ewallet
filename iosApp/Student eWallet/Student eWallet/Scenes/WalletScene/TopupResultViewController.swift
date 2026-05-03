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
        view.backgroundColor = .systemBackground
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
        statusLabel.text = "Giao dịch thành công"
        statusLabel.font = .systemFont(ofSize: 24, weight: .bold)
        statusLabel.textAlignment = .center

        let amountLabel = UILabel()
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) VND"
        amountLabel.font = .systemFont(ofSize: 34, weight: .bold)
        amountLabel.textAlignment = .center
        amountLabel.textColor = .label

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
        buttonStack.axis = .vertical
        buttonStack.spacing = 14

        let resultCard = UIView()
        resultCard.applyAppCardStyle()

        let stack = UIStackView(arrangedSubviews: [iconView, statusLabel, amountLabel, noteLabel, infoCard, buttonStack])
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
            makeRow(title: "Dịch vụ", value: "Nạp tiền vào ví"),
            makeRow(title: "Mã giao dịch", value: orderId),
            makeRow(title: "Thời gian tạo", value: Self.timeFormatter.string(from: Date()))
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

    @objc private func tapOpenAgain() {
        if let url = URL(string: paymentUrl) {
            UIApplication.shared.open(url)
        }
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
