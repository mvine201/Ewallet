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
    private let statisticsCard = UIControl()
    private let statisticsPreviewChartView = CustomPieChartView()
    private let statisticsLegendStack = UIStackView()
    private let statisticsSummaryLabel = UILabel()
    private let statisticsHintLabel = UILabel()

    private var currentBalance: Double = 0
    private var isBalanceHidden = false
    private var currentUser: AuthUser?
    private var hasShownVerificationPrompt = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trang chủ"
        view.backgroundColor = .systemBackground
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
        stack.applyAppCardStyle(cornerRadius: 20)
        return stack
    }

    private func makeQuickActionButton(title: String, image: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = UIImage(systemName: image)
        configuration.imagePlacement = .top
        configuration.imagePadding = 6
        configuration.baseBackgroundColor = .appElevatedSurfaceBackground
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 6, bottom: 12, trailing: 6)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.applyNeutralSurfaceButtonStyle(cornerRadius: 14)
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
        stack.applyAppCardStyle(cornerRadius: 20)
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
        titleLabel.text = "Thống kê chi tiêu"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        statisticsPreviewChartView.translatesAutoresizingMaskIntoConstraints = false
        statisticsPreviewChartView.heightAnchor.constraint(equalToConstant: 170).isActive = true

        statisticsLegendStack.axis = .vertical
        statisticsLegendStack.spacing = 8

        statisticsSummaryLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statisticsSummaryLabel.textColor = .secondaryLabel
        statisticsSummaryLabel.numberOfLines = 0
        statisticsSummaryLabel.text = "Đang tải thống kê..."

        statisticsHintLabel.text = "Chạm để xem chi tiết và AI gợi ý"
        statisticsHintLabel.font = .systemFont(ofSize: 13, weight: .bold)
        statisticsHintLabel.textColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)

        let bodyStack = UIStackView(arrangedSubviews: [statisticsPreviewChartView, statisticsLegendStack])
        bodyStack.axis = .horizontal
        bodyStack.spacing = 16
        bodyStack.alignment = .center
        bodyStack.distribution = .fillEqually

        let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronView.tintColor = .tertiaryLabel

        let footerRow = UIStackView(arrangedSubviews: [statisticsHintLabel, chevronView])
        footerRow.axis = .horizontal
        footerRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyStack, statisticsSummaryLabel, footerRow])
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        stack.isUserInteractionEnabled = false

        statisticsCard.addTarget(self, action: #selector(tapStatistics), for: .touchUpInside)
        statisticsCard.applyAppCardStyle(cornerRadius: 20)
        statisticsCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: statisticsCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: statisticsCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: statisticsCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: statisticsCard.bottomAnchor)
        ])

        applyStatisticsPreviewPlaceholder()
        return statisticsCard
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
                let user = try await AuthService.shared.getMe()

                guard user.isVerified else {
                    await MainActor.run {
                        self.setLoading(false)
                        self.currentUser = user
                        self.phoneLabel.text = user.phone
                        self.currentBalance = 0
                        self.balanceLabel.text = "Cần xác thực"
                        self.visibilityButton.isEnabled = false
                        self.applyStatisticsPreviewPlaceholder()
                        if !self.hasShownVerificationPrompt {
                            self.hasShownVerificationPrompt = true
                            self.showStudentVerificationRequired()
                        }
                    }
                    return
                }

                let wallet = try await AuthService.shared.getMyWallet()
                await MainActor.run {
                    self.setLoading(false)
                    self.currentUser = user
                    self.phoneLabel.text = user.phone
                    self.visibilityButton.isEnabled = true
                    self.currentBalance = wallet.balance
                    self.updateBalanceText()
                    self.loadStatisticsPreview()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func loadStatisticsPreview() {
        if currentUser?.isVerified == false || TokenStore.shared.currentUser?.isVerified == false {
            applyStatisticsPreviewPlaceholder()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let stats = try await StatisticsService.shared.getStats(period: .month)
                await MainActor.run {
                    self.applyStatisticsPreview(stats)
                }
            } catch {
                await MainActor.run {
                    self.applyStatisticsPreviewPlaceholder()
                }
            }
        }
    }

    private func applyStatisticsPreview(_ stats: AnalyticsStatsData) {
        let topCategories = Array(stats.categories.prefix(4))
        let segments = topCategories.map {
            CustomPieChartView.Segment(
                value: $0.amount,
                color: UIColor(analyticsHex: $0.colorHex) ?? .systemGray
            )
        }
        statisticsPreviewChartView.configure(
            segments: segments,
            centerTitle: Self.currencyFormatter.string(from: NSNumber(value: stats.totalExpense)) ?? "0₫",
            centerSubtitle: "Chi tiêu tháng này"
        )

        statisticsLegendStack.arrangedSubviews.forEach { view in
            statisticsLegendStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if topCategories.isEmpty {
            statisticsLegendStack.addArrangedSubview(makeLegendItem(color: .systemGray, title: "Chưa có dữ liệu"))
            statisticsSummaryLabel.text = "Chưa có giao dịch chi tiêu trong tháng này."
            return
        }

        topCategories.forEach { category in
            statisticsLegendStack.addArrangedSubview(
                makeLegendItem(
                    color: UIColor(analyticsHex: category.colorHex) ?? .systemGray,
                    title: "\(category.title) • \(String(format: "%.0f%%", category.percentage))"
                )
            )
        }

        if let top = topCategories.first {
            statisticsSummaryLabel.text = "Nổi bật nhất hiện là \(top.title), chiếm \(String(format: "%.1f%%", top.percentage)) tổng chi."
        } else {
            statisticsSummaryLabel.text = "Chạm để xem chi tiết thống kê chi tiêu."
        }
    }

    private func applyStatisticsPreviewPlaceholder() {
        statisticsPreviewChartView.configure(
            segments: [],
            centerTitle: "0₫",
            centerSubtitle: "Chưa có dữ liệu",
            animated: false
        )
        statisticsLegendStack.arrangedSubviews.forEach { view in
            statisticsLegendStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        statisticsLegendStack.addArrangedSubview(makeLegendItem(color: .systemGray, title: "Chưa có dữ liệu chi tiêu"))
        statisticsSummaryLabel.text = "Chạm để xem chi tiết thống kê và AI gợi ý."
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
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        isBalanceHidden.toggle()
        updateBalanceText()
    }

    @objc private func tapTransfer() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        navigationController?.pushViewController(TransferViewController(), animated: true)
    }

    @objc private func tapTopup() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        navigationController?.pushViewController(TopupViewController(), animated: true)
    }

    @objc private func tapWithdraw() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        showMessage(title: "Rút tiền", message: "Chức năng rút tiền sẽ được phát triển sau.")
    }

    @objc private func tapSavingsFund() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        navigationController?.pushViewController(SavingsJarListViewController(), animated: true)
    }

    @objc private func tapStatistics() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        navigationController?.pushViewController(StatisticsViewController(), animated: true)
    }

    @objc private func tapPhoneTopup() {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
        showMessage(title: "Nạp điện thoại", message: "Chức năng nạp điện thoại sẽ được phát triển sau.")
    }

    @objc private func tapService(_ sender: UIButton) {
        guard isStudentVerified else {
            showStudentVerificationRequired()
            return
        }
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

    private var isStudentVerified: Bool {
        currentUser?.isVerified ?? TokenStore.shared.currentUser?.isVerified ?? false
    }
}
