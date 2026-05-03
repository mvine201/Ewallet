import UIKit

final class StatisticsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let segmentedControl = UISegmentedControl(items: [StatisticsPeriod.week.title, StatisticsPeriod.month.title])
    private let activity = UIActivityIndicatorView(style: .medium)

    private let chartView = CustomPieChartView()
    private let rangeLabel = UILabel()
    private let summaryLabel = UILabel()
    private let inflowValueLabel = UILabel()
    private let expenseValueLabel = UILabel()
    private let netValueLabel = UILabel()

    private let breakdownStack = UIStackView()

    private let aiStatusLabel = PaddingLabel()
    private let aiHeadlineLabel = UILabel()
    private let aiSummaryLabel = UILabel()
    private let aiFocusLabel = UILabel()
    private let aiFocusValueLabel = UILabel()
    private let aiActionsStack = UIStackView()
    private let aiBadgesStack = UIStackView()

    private var selectedPeriod: StatisticsPeriod = .month

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thống kê chi tiêu"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadAnalytics()
    }

    private func setupLayout() {
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(changePeriod), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16

        rangeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        rangeLabel.textColor = .secondaryLabel

        summaryLabel.font = .systemFont(ofSize: 15)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.numberOfLines = 0

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(equalToConstant: 260).isActive = true

        breakdownStack.axis = .vertical
        breakdownStack.spacing = 12

        aiStatusLabel.font = .systemFont(ofSize: 12, weight: .bold)
        aiStatusLabel.layer.cornerRadius = 12
        aiStatusLabel.layer.masksToBounds = true

        aiHeadlineLabel.font = .systemFont(ofSize: 20, weight: .bold)
        aiHeadlineLabel.numberOfLines = 0

        aiSummaryLabel.font = .systemFont(ofSize: 15)
        aiSummaryLabel.textColor = .secondaryLabel
        aiSummaryLabel.numberOfLines = 0

        aiFocusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        aiFocusLabel.textColor = .secondaryLabel

        aiFocusValueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        aiFocusValueLabel.numberOfLines = 0

        aiActionsStack.axis = .vertical
        aiActionsStack.spacing = 10

        aiBadgesStack.axis = .vertical
        aiBadgesStack.spacing = 8

        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false

        let overviewCard = makeOverviewCard()
        let breakdownCard = makeBreakdownCard()
        let aiCard = makeAICard()

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(activity)

        [segmentedControl, overviewCard, breakdownCard, aiCard].forEach { contentStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeOverviewCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Tổng quan"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        let metricRow = UIStackView(arrangedSubviews: [
            makeMetricItem(title: "Tiền vào", valueLabel: inflowValueLabel),
            makeMetricItem(title: "Chi ra", valueLabel: expenseValueLabel),
            makeMetricItem(title: "Chênh lệch", valueLabel: netValueLabel),
        ])
        metricRow.axis = .horizontal
        metricRow.spacing = 10
        metricRow.distribution = .fillEqually

        let stack = makeCardStack()
        [titleLabel, rangeLabel, chartView, summaryLabel, metricRow].forEach { stack.addArrangedSubview($0) }
        return stack
    }

    private func makeBreakdownCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Cơ cấu chi tiêu"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        let stack = makeCardStack()
        [titleLabel, breakdownStack].forEach { stack.addArrangedSubview($0) }
        return stack
    }

    private func makeAICard() -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: "sparkles"))
        iconView.tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let headerTitle = UILabel()
        headerTitle.text = "AI gợi ý"
        headerTitle.font = .systemFont(ofSize: 18, weight: .bold)

        let headerTextStack = UIStackView(arrangedSubviews: [headerTitle, aiStatusLabel])
        headerTextStack.axis = .vertical
        headerTextStack.spacing = 8
        headerTextStack.alignment = .leading

        let headerRow = UIStackView(arrangedSubviews: [iconView, headerTextStack])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .top

        let focusCard = UIView()
        focusCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        focusCard.layer.cornerRadius = 12

        let focusStack = UIStackView(arrangedSubviews: [aiFocusLabel, aiFocusValueLabel])
        focusStack.axis = .vertical
        focusStack.spacing = 6
        focusStack.isLayoutMarginsRelativeArrangement = true
        focusStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        focusStack.translatesAutoresizingMaskIntoConstraints = false
        focusCard.addSubview(focusStack)
        NSLayoutConstraint.activate([
            focusStack.leadingAnchor.constraint(equalTo: focusCard.leadingAnchor),
            focusStack.trailingAnchor.constraint(equalTo: focusCard.trailingAnchor),
            focusStack.topAnchor.constraint(equalTo: focusCard.topAnchor),
            focusStack.bottomAnchor.constraint(equalTo: focusCard.bottomAnchor)
        ])

        let stack = makeCardStack()
        [headerRow, aiHeadlineLabel, aiSummaryLabel, focusCard, aiActionsStack, aiBadgesStack].forEach {
            stack.addArrangedSubview($0)
        }
        return stack
    }

    private func makeCardStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 14
        stack.layer.masksToBounds = true
        return stack
    }

    private func makeMetricItem(title: String, valueLabel: UILabel) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 2
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        stack.backgroundColor = .systemBackground
        stack.layer.cornerRadius = 12
        return stack
    }

    @objc private func changePeriod() {
        selectedPeriod = segmentedControl.selectedSegmentIndex == 0 ? .week : .month
        loadAnalytics()
    }

    private func loadAnalytics() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                async let statsRequest = StatisticsService.shared.getStats(period: self.selectedPeriod)
                async let aiRequest = StatisticsService.shared.getAIPlan(period: self.selectedPeriod)

                let stats = try await statsRequest
                let aiPlan = try? await aiRequest

                await MainActor.run {
                    self.setLoading(false)
                    self.applyStats(stats)
                    if let aiPlan {
                        self.applyAIPlan(aiPlan)
                    } else {
                        self.applyFallbackAI(stats: stats)
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func applyStats(_ stats: AnalyticsStatsData) {
        rangeLabel.text = "\(displayDate(stats.startDate)) - \(displayDate(stats.endDate))"

        let segments = stats.categories.map {
            CustomPieChartView.Segment(
                value: $0.amount,
                color: UIColor(analyticsHex: $0.colorHex) ?? .systemGray
            )
        }
        chartView.configure(
            segments: segments,
            centerTitle: formatAmount(stats.totalExpense),
            centerSubtitle: selectedPeriod == .week ? "Chi tiêu tuần này" : "Chi tiêu tháng này"
        )

        if let top = stats.categories.first {
            summaryLabel.text = "Nhóm chi lớn nhất là \(top.title), chiếm \(formatPercent(top.percentage)) tổng chi."
        } else {
            summaryLabel.text = "Chưa có giao dịch chi tiêu trong kỳ này."
        }

        inflowValueLabel.text = formatAmount(stats.totalInflow)
        inflowValueLabel.textColor = .systemGreen
        expenseValueLabel.text = formatAmount(stats.totalExpense)
        expenseValueLabel.textColor = .systemRed
        netValueLabel.text = formatSignedAmount(stats.netCashFlow)
        netValueLabel.textColor = stats.netCashFlow >= 0 ? .systemGreen : .systemOrange

        breakdownStack.arrangedSubviews.forEach { view in
            breakdownStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if stats.categories.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Chưa có dữ liệu chi tiêu để phân tích."
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.numberOfLines = 0
            breakdownStack.addArrangedSubview(emptyLabel)
            return
        }

        stats.categories.forEach { category in
            breakdownStack.addArrangedSubview(makeBreakdownRow(category))
        }
    }

    private func makeBreakdownRow(_ category: AnalyticsCategory) -> UIView {
        let dot = UIView()
        dot.backgroundColor = UIColor(analyticsHex: category.colorHex) ?? .systemGray
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = category.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(category.transactionCount) giao dịch"
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel

        let amountLabel = UILabel()
        amountLabel.text = formatAmount(category.amount)
        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        amountLabel.textAlignment = .right

        let percentLabel = UILabel()
        percentLabel.text = formatPercent(category.percentage)
        percentLabel.font = .systemFont(ofSize: 12, weight: .bold)
        percentLabel.textColor = UIColor(analyticsHex: category.colorHex) ?? .systemGray
        percentLabel.textAlignment = .right

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [amountLabel, percentLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing

        let rowStack = UIStackView(arrangedSubviews: [dot, leftStack, rightStack])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    private func applyAIPlan(_ plan: AnalyticsAIPlanData) {
        let style = aiStyle(for: plan.status)
        aiStatusLabel.text = "  \(style.label)  "
        aiStatusLabel.backgroundColor = style.background
        aiStatusLabel.textColor = style.foreground

        aiHeadlineLabel.text = plan.headline
        aiSummaryLabel.text = plan.summary
        aiFocusLabel.text = plan.focusLabel.uppercased()
        aiFocusValueLabel.text = plan.focusValue

        aiActionsStack.arrangedSubviews.forEach { view in
            aiActionsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        plan.actions.forEach { aiActionsStack.addArrangedSubview(makeAIActionRow($0)) }

        aiBadgesStack.arrangedSubviews.forEach { view in
            aiBadgesStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        plan.badges.forEach { aiBadgesStack.addArrangedSubview(makeBadgeLabel($0)) }
    }

    private func applyFallbackAI(stats: AnalyticsStatsData) {
        let fallback = AnalyticsAIPlanData(
            period: stats.period,
            generatedAt: "",
            status: "watch",
            headline: "AI đang dùng gợi ý rút gọn",
            summary: stats.categories.first.map { "Nhóm chi lớn nhất hiện là \($0.title)." } ?? "Chưa đủ dữ liệu để AI gợi ý sâu hơn.",
            focusLabel: "Ưu tiên kỳ này",
            focusValue: "Theo dõi nhóm chi lớn nhất và tăng dần phần dành cho tiết kiệm.",
            actions: [
                AnalyticsAIAction(title: "Xem theo 2 chu kỳ", detail: "Đổi giữa Tuần và Tháng để nhận ra khoản tăng nhanh.", tag: "Mẹo dùng nhanh", emphasis: "watch")
            ],
            badges: ["Fallback AI"],
            metrics: AnalyticsAIMetrics(stabilityScore: 60, needsRate: 0, wantsRate: 0, savingsRate: 0),
            source: "ios-fallback"
        )
        applyAIPlan(fallback)
    }

    private func makeAIActionRow(_ action: AnalyticsAIAction) -> UIView {
        let tagLabel = PaddingLabel()
        tagLabel.text = " \(action.tag) "
        tagLabel.font = .systemFont(ofSize: 11, weight: .bold)
        tagLabel.layer.cornerRadius = 10
        tagLabel.layer.masksToBounds = true

        switch action.emphasis {
        case "cut":
            tagLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            tagLabel.textColor = .systemRed
        case "save":
            tagLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            tagLabel.textColor = .systemGreen
        default:
            tagLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            tagLabel.textColor = .systemBlue
        }

        let titleLabel = UILabel()
        titleLabel.text = action.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let detailLabel = UILabel()
        detailLabel.text = action.detail
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let stack = UIStackView(arrangedSubviews: [tagLabel, textStack])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .top

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    private func makeBadgeLabel(_ text: String) -> UIView {
        let label = PaddingLabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }

    private func aiStyle(for status: String) -> (label: String, background: UIColor, foreground: UIColor) {
        switch status {
        case "alert":
            return ("Cần siết lại", UIColor.systemRed.withAlphaComponent(0.15), .systemRed)
        case "watch":
            return ("Nên theo dõi", UIColor.systemOrange.withAlphaComponent(0.15), .systemOrange)
        default:
            return ("Đang ổn", UIColor.systemGreen.withAlphaComponent(0.15), .systemGreen)
        }
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func displayDate(_ value: String) -> String {
        let parts = value.split(separator: "-")
        guard parts.count == 3 else { return value }
        return "\(parts[2])/\(parts[1])/\(parts[0])"
    }

    private func formatAmount(_ amount: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) VND"
    }

    private func formatSignedAmount(_ amount: Double) -> String {
        let prefix = amount >= 0 ? "+" : "-"
        return prefix + formatAmount(abs(amount))
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
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

private final class PaddingLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 16, height: size.height + 12)
    }
}
