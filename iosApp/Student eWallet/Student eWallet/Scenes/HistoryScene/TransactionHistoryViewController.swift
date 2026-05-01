//
//  TransactionHistoryViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class TransactionHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum TypeFilter: String, CaseIterable {
        case all = "Tất cả"
        case topup = "Nạp tiền"
        case transferOut = "Chuyển tiền đi"
        case transferIn = "Nhận tiền vào"
        case payment = "Thanh toán"
        case refund = "Hoàn tiền"
    }

    private enum TimeFilter: String, CaseIterable {
        case all = "Tất cả"
        case today = "Hôm nay"
        case thisMonth = "Tháng này"
    }

    private let typeFilterStack = UIStackView()
    private let timeFilterStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activity = UIActivityIndicatorView(style: .medium)
    private var transactions: [WalletTransaction] = []
    private var filteredTransactions: [WalletTransaction] = []
    private var selectedTypeFilter: TypeFilter = .all
    private var selectedTimeFilter: TimeFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lịch sử"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadTransactions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTransactions()
    }

    private func setupLayout() {
        typeFilterStack.axis = .horizontal
        typeFilterStack.spacing = 8
        typeFilterStack.alignment = .fill

        timeFilterStack.axis = .horizontal
        timeFilterStack.spacing = 8
        timeFilterStack.alignment = .fill

        TypeFilter.allCases.forEach { typeFilterStack.addArrangedSubview(makeChip(title: $0.rawValue, action: #selector(tapTypeFilter(_:)))) }
        TimeFilter.allCases.forEach { timeFilterStack.addArrangedSubview(makeChip(title: $0.rawValue, action: #selector(tapTimeFilter(_:)))) }

        let typeScroll = makeHorizontalScroll(containing: typeFilterStack)
        let timeScroll = makeHorizontalScroll(containing: timeFilterStack)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionHistoryCell.self, forCellReuseIdentifier: TransactionHistoryCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false

        let filterStack = UIStackView(arrangedSubviews: [typeScroll, timeScroll])
        filterStack.axis = .vertical
        filterStack.spacing = 10
        filterStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(filterStack)
        view.addSubview(tableView)
        view.addSubview(activity)

        NSLayoutConstraint.activate([
            filterStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 4),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        updateChipSelection()
    }

    private func makeHorizontalScroll(containing stack: UIStackView) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 38)
        ])

        return scrollView
    }

    private func makeChip(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func loadTransactions() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let transactions = try await TransactionService.shared.getTransactions()
                await MainActor.run {
                    self.setLoading(false)
                    self.transactions = transactions
                    self.applyFilters()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func applyFilters() {
        filteredTransactions = transactions.filter { transaction in
            matchesType(transaction) && matchesTime(transaction)
        }
        tableView.reloadData()
        updateChipSelection()
    }

    private func matchesType(_ transaction: WalletTransaction) -> Bool {
        switch selectedTypeFilter {
        case .all:
            return true
        case .topup:
            return transaction.type == "topup"
        case .transferOut:
            return transaction.type == "transfer" && !transaction.isIncoming
        case .transferIn:
            return transaction.type == "transfer" && transaction.isIncoming
        case .payment:
            return transaction.type == "payment"
        case .refund:
            return transaction.type == "refund"
        }
    }

    private func matchesTime(_ transaction: WalletTransaction) -> Bool {
        guard selectedTimeFilter != .all else { return true }
        guard let date = parseDate(transaction.createdAt) else { return false }

        let calendar = Calendar.current
        switch selectedTimeFilter {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .thisMonth:
            let now = Date()
            return calendar.component(.month, from: date) == calendar.component(.month, from: now)
                && calendar.component(.year, from: date) == calendar.component(.year, from: now)
        }
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        return Self.isoFormatterWithFractionalSeconds.date(from: value)
            ?? Self.isoFormatter.date(from: value)
    }

    @objc private func tapTypeFilter(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let filter = TypeFilter.allCases.first(where: { $0.rawValue == title }) else {
            return
        }
        selectedTypeFilter = filter
        applyFilters()
    }

    @objc private func tapTimeFilter(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let filter = TimeFilter.allCases.first(where: { $0.rawValue == title }) else {
            return
        }
        selectedTimeFilter = filter
        applyFilters()
    }

    private func updateChipSelection() {
        updateButtons(in: typeFilterStack, selectedTitle: selectedTypeFilter.rawValue)
        updateButtons(in: timeFilterStack, selectedTitle: selectedTimeFilter.rawValue)
    }

    private func updateButtons(in stack: UIStackView, selectedTitle: String) {
        stack.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
            let isSelected = button.title(for: .normal) == selectedTitle
            button.backgroundColor = isSelected ? UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1) : .secondarySystemGroupedBackground
            button.tintColor = isSelected ? .white : .label
        }
    }

    private func setLoading(_ loading: Bool) {
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredTransactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transaction = filteredTransactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionHistoryCell.reuseIdentifier, for: indexPath) as! TransactionHistoryCell
        cell.configure(with: transaction)
        return cell
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static let isoFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

final class TransactionHistoryCell: UITableViewCell {
    static let reuseIdentifier = "TransactionHistoryCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let rowStack = UIStackView(arrangedSubviews: [iconView, textStack, amountLabel])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with transaction: WalletTransaction) {
        let isIncoming = transaction.isIncoming
        titleLabel.text = transaction.displayType ?? displayType(transaction)
        subtitleLabel.text = [
            transaction.description,
            displayStatus(transaction.status),
            displayDate(transaction.createdAt)
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
        amountLabel.text = "\(isIncoming ? "+" : "-")\(formatAmount(transaction.amount))"
        amountLabel.textColor = isIncoming ? .systemGreen : .systemGray
        iconView.image = UIImage(systemName: iconName(for: transaction, incoming: isIncoming))
        iconView.tintColor = isIncoming ? .systemGreen : .systemGray
        selectionStyle = .none
    }

    private func displayType(_ transaction: WalletTransaction) -> String {
        switch transaction.type {
        case "topup": return "Nạp tiền"
        case "transfer": return transaction.isIncoming ? "Nhận tiền" : "Chuyển tiền"
        case "payment": return "Thanh toán dịch vụ"
        case "refund": return "Hoàn tiền"
        default: return transaction.type
        }
    }

    private func displayStatus(_ status: String) -> String {
        switch status {
        case "success": return "Thành công"
        case "pending": return "Đang xử lý"
        case "failed": return "Thất bại"
        default: return status
        }
    }

    private func iconName(for transaction: WalletTransaction, incoming: Bool) -> String {
        switch transaction.type {
        case "topup": return "plus.circle.fill"
        case "transfer": return incoming ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
        case "payment": return "doc.text.fill"
        case "refund": return "arrow.uturn.left.circle.fill"
        default: return "clock.fill"
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) VND"
    }

    private func displayDate(_ date: String?) -> String? {
        guard let date else { return nil }
        return String(date.prefix(10))
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

private extension WalletTransaction {
    var isIncoming: Bool {
        if direction == "in" { return true }
        if direction == "out" { return false }
        if type == "topup" || type == "refund" { return true }
        if type == "transfer" {
            return description?.lowercased().hasPrefix("nhận tiền") == true
        }
        return false
    }
}
