//
//  WalletViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class WalletViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let phoneValueLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wallet"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadWallet()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWallet()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill

        activity.hidesWhenStopped = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let infoCard = makeInfoCard()
        let actionGrid = makeActionGrid()

        contentStack.addArrangedSubview(infoCard)
        contentStack.addArrangedSubview(actionGrid)
        contentStack.addArrangedSubview(activity)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeInfoCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "My wallet"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label

        phoneValueLabel.text = "Đang tải..."
        phoneValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        phoneValueLabel.textColor = .label

        balanceValueLabel.text = "0 VND"
        balanceValueLabel.font = .systemFont(ofSize: 30, weight: .bold)
        balanceValueLabel.textColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        balanceValueLabel.adjustsFontSizeToFitWidth = true
        balanceValueLabel.minimumScaleFactor = 0.75

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            makeInfoRow(title: "Số tài khoản", valueLabel: phoneValueLabel),
            makeInfoRow(title: "Số dư", valueLabel: balanceValueLabel)
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeInfoRow(title: String, valueLabel: UILabel) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func makeActionGrid() -> UIStackView {
        let firstRow = UIStackView(arrangedSubviews: [
            makeActionButton(title: "Nạp", image: "plus.circle.fill", action: #selector(tapTopup)),
            makeActionButton(title: "Rút", image: "minus.circle.fill", action: #selector(tapWithdraw))
        ])
        let secondRow = UIStackView(arrangedSubviews: [
            makeActionButton(title: "Chuyển tiền", image: "arrow.left.arrow.right.circle.fill", action: #selector(tapTransfer)),
            makeActionButton(title: "Dịch vụ", image: "doc.text.fill", action: #selector(tapServicePayment))
        ])
        let thirdRow = UIStackView(arrangedSubviews: [
            makeActionButton(title: "Nạp điện thoại", image: "iphone.gen2.circle.fill", action: #selector(tapPhoneTopup))
        ])

        [firstRow, secondRow, thirdRow].forEach { row in
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
        }

        let stack = UIStackView(arrangedSubviews: [firstRow, secondRow, thirdRow])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeActionButton(title: String, image: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: image)
        configuration.imagePlacement = .top
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 10, bottom: 16, trailing: 10)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(equalToConstant: 92).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func loadWallet() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                async let user = AuthService.shared.getMe()
                async let wallet = AuthService.shared.getMyWallet()
                let result = try await (user, wallet)
                await MainActor.run {
                    self.setLoading(false)
                    self.phoneValueLabel.text = result.0.phone
                    self.balanceValueLabel.text = Self.currencyFormatter.string(from: NSNumber(value: result.1.balance)) ?? "\(result.1.balance) VND"
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
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    @objc private func tapTopup() {
        navigationController?.pushViewController(TopupViewController(), animated: true)
    }

    @objc private func tapWithdraw() {
        showMessage(title: "Rút tiền", message: "Chức năng rút tiền sẽ được phát triển sau.")
    }

    @objc private func tapTransfer() {
        navigationController?.pushViewController(TransferViewController(), animated: true)
    }

    @objc private func tapServicePayment() {
        showMessage(title: "Thanh toán dịch vụ", message: "Chức năng thanh toán dịch vụ sẽ được phát triển sau.")
    }

    @objc private func tapPhoneTopup() {
        showMessage(title: "Nạp tiền điện thoại", message: "Chức năng nạp tiền điện thoại sẽ được phát triển sau.")
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
