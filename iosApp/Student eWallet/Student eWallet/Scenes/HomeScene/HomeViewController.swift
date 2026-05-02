//
//  HomeViewController.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 10/4/26.
//

import UIKit

final class HomeViewController: UIViewController {

    private struct HomeItem {
        let title: String
        let systemImage: String
        let action: Selector
        let serviceType: String?
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let phoneLabel = UILabel()
    private let balanceLabel = UILabel()
    private let visibilityButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)

    private var currentBalance: Double = 0
    private var isBalanceHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trang chủ"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadWalletSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWalletSummary()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(makeWalletCard())
        contentStack.addArrangedSubview(makeServicesSection())
        contentStack.addArrangedSubview(makeStatisticsSection())
        contentStack.addArrangedSubview(activity)

        activity.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36)
        ])
    }

    private func makeWalletCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Ví của tôi"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        phoneLabel.text = "Đang tải..."
        phoneLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        phoneLabel.textColor = .secondaryLabel

        balanceLabel.text = "0đ"
        balanceLabel.font = .systemFont(ofSize: 30, weight: .bold)
        balanceLabel.textColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.7

        visibilityButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        visibilityButton.tintColor = .secondaryLabel
        visibilityButton.addTarget(self, action: #selector(toggleBalanceVisibility), for: .touchUpInside)
        visibilityButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        visibilityButton.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let balanceRow = UIStackView(arrangedSubviews: [balanceLabel, visibilityButton])
        balanceRow.axis = .horizontal
        balanceRow.alignment = .center
        balanceRow.spacing = 8

        let quickActions = UIStackView(arrangedSubviews: [
            makeQuickActionButton(title: "Chuyển tiền", image: "arrow.left.arrow.right.circle.fill", action: #selector(tapTransfer)),
            makeQuickActionButton(title: "Nạp", image: "plus.circle.fill", action: #selector(tapTopup)),
            makeQuickActionButton(title: "Rút", image: "minus.circle.fill", action: #selector(tapWithdraw))
        ])
        quickActions.axis = .horizontal
        quickActions.spacing = 10
        quickActions.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, phoneLabel, balanceRow, quickActions])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 16, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeQuickActionButton(title: String, image: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: image)
        configuration.imagePlacement = .top
        configuration.imagePadding = 6
        configuration.baseBackgroundColor = .systemBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 6, bottom: 12, trailing: 6)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(equalToConstant: 74).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeServicesSection() -> UIView {
        let items = [
            HomeItem(title: "Học phí", systemImage: "graduationcap.fill", action: #selector(tapService(_:)), serviceType: "tuition"),
            HomeItem(title: "Giữ xe", systemImage: "parkingsign.circle.fill", action: #selector(tapService(_:)), serviceType: "parking"),
            HomeItem(title: "Đoàn phí", systemImage: "person.3.fill", action: #selector(tapService(_:)), serviceType: "union_fee"),
            HomeItem(title: "Quỹ tiết kiệm", systemImage: "banknote.fill", action: #selector(tapSavingsFund), serviceType: nil),
            HomeItem(title: "Dịch vụ", systemImage: "doc.text.fill", action: #selector(tapService(_:)), serviceType: nil),
            HomeItem(title: "Nạp điện thoại", systemImage: "iphone.gen2.circle.fill", action: #selector(tapPhoneTopup), serviceType: nil),
            HomeItem(title: "Bảo hiểm", systemImage: "shield.fill", action: #selector(tapService(_:)), serviceType: "insurance"),
            HomeItem(title: "Ký túc xá", systemImage: "building.2.fill", action: #selector(tapService(_:)), serviceType: "dormitory")
        ]

        return makeGridSection(title: "Dịch vụ", items: items)
    }

    private func makeGridSection(title: String, items: [HomeItem]) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 14

        stride(from: 0, to: items.count, by: 4).forEach { start in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.distribution = .fillEqually

            let rowItems = Array(items[start..<min(start + 4, items.count)])
            rowItems.forEach { item in
                row.addArrangedSubview(makeServiceButton(item))
            }

            if rowItems.count < 4 {
                (rowItems.count..<4).forEach { _ in
                    let spacer = UIView()
                    spacer.heightAnchor.constraint(equalToConstant: 78).isActive = true
                    row.addArrangedSubview(spacer)
                }
            }

            gridStack.addArrangedSubview(row)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, gridStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeServiceButton(_ item: HomeItem) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = item.title
        configuration.image = UIImage(systemName: item.systemImage)
        configuration.imagePlacement = .top
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.accessibilityIdentifier = item.serviceType
        button.heightAnchor.constraint(equalToConstant: 78).isActive = true
        button.addTarget(self, action: item.action, for: .touchUpInside)
        return button
    }

    private func makeStatisticsSection() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Thống kê"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        let chartView = SpendingPieChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(equalToConstant: 170).isActive = true

        let legendStack = UIStackView(arrangedSubviews: [
            makeLegendItem(color: .systemBlue, title: "Học phí"),
            makeLegendItem(color: .systemGreen, title: "Ăn uống"),
            makeLegendItem(color: .systemOrange, title: "Giữ xe"),
            makeLegendItem(color: .systemGray, title: "Khác")
        ])
        legendStack.axis = .vertical
        legendStack.spacing = 8

        let bodyStack = UIStackView(arrangedSubviews: [chartView, legendStack])
        bodyStack.axis = .horizontal
        bodyStack.spacing = 16
        bodyStack.alignment = .center
        bodyStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeLegendItem(color: UIColor, title: String) -> UIView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [dot, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }

    private func loadWalletSummary() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                async let userRequest = AuthService.shared.getMe()
                async let walletRequest = AuthService.shared.getMyWallet()
                let (user, wallet) = try await (userRequest, walletRequest)
                await MainActor.run {
                    self.setLoading(false)
                    self.phoneLabel.text = user.phone
                    self.currentBalance = wallet.balance
                    self.updateBalanceText()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func updateBalanceText() {
        balanceLabel.text = isBalanceHidden
            ? "****"
            : Self.currencyFormatter.string(from: NSNumber(value: currentBalance)) ?? "\(currentBalance) VND"
        visibilityButton.setImage(
            UIImage(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill"),
            for: .normal
        )
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    @objc private func toggleBalanceVisibility() {
        isBalanceHidden.toggle()
        updateBalanceText()
    }

    @objc private func tapTransfer() {
        navigationController?.pushViewController(TransferViewController(), animated: true)
    }

    @objc private func tapTopup() {
        navigationController?.pushViewController(TopupViewController(), animated: true)
    }

    @objc private func tapWithdraw() {
        showMessage(title: "Rút tiền", message: "Chức năng rút tiền sẽ được phát triển sau.")
    }

    @objc private func tapSavingsFund() {
        showMessage(title: "Quỹ tiết kiệm", message: "Chức năng quỹ tiết kiệm sẽ được phát triển sau.")
    }

    @objc private func tapPhoneTopup() {
        showMessage(title: "Nạp điện thoại", message: "Chức năng nạp điện thoại sẽ được phát triển sau.")
    }

    @objc private func tapService(_ sender: UIButton) {
        navigationController?.pushViewController(
            ServiceListViewController(serviceType: sender.accessibilityIdentifier),
            animated: true
        )
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

private final class SpendingPieChartView: UIView {
    private let segments: [(value: CGFloat, color: UIColor)] = [
        (45, .systemBlue),
        (20, .systemGreen),
        (10, .systemOrange),
        (25, .systemGray)
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let size = min(rect.width, rect.height) - 8
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = size / 2
        let total = segments.reduce(CGFloat(0)) { $0 + $1.value }
        var startAngle = -CGFloat.pi / 2

        segments.forEach { segment in
            let endAngle = startAngle + (segment.value / total) * 2 * CGFloat.pi
            context.setFillColor(segment.color.cgColor)
            context.move(to: center)
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            context.closePath()
            context.fillPath()
            startAngle = endAngle
        }

        context.setFillColor(UIColor.secondarySystemGroupedBackground.cgColor)
        context.addEllipse(in: CGRect(x: center.x - radius * 0.48, y: center.y - radius * 0.48, width: radius * 0.96, height: radius * 0.96))
        context.fillPath()
    }
}
