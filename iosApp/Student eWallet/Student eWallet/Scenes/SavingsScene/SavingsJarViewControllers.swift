import UIKit

final class SavingsJarListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let titleLabel = UILabel()
    private let createButton = UIButton(type: .system)
    private let selectButton = UIButton(type: .system)
    private let deleteSelectedButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activity = UIActivityIndicatorView(style: .medium)
    private var jars: [SavingsJarItem] = []
    private var selectedJarIds = Set<String>()
    private var isSelectingMultiple = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Quỹ tiết kiệm"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadJars()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadJars()
    }

    private func setupLayout() {
        titleLabel.text = "Quỹ tiết kiệm"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Tạo quỹ"
        buttonConfig.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        buttonConfig.baseForegroundColor = .white
        buttonConfig.cornerStyle = .large
        createButton.configuration = buttonConfig
        createButton.addTarget(self, action: #selector(tapCreateJar), for: .touchUpInside)

        var selectConfig = UIButton.Configuration.plain()
        selectConfig.title = "Chọn nhiều"
        selectButton.configuration = selectConfig
        selectButton.addTarget(self, action: #selector(tapToggleSelectionMode), for: .touchUpInside)

        var deleteConfig = UIButton.Configuration.filled()
        deleteConfig.title = "Xoá quỹ đã chọn"
        deleteConfig.baseBackgroundColor = .systemRed
        deleteConfig.baseForegroundColor = .white
        deleteConfig.cornerStyle = .large
        deleteSelectedButton.configuration = deleteConfig
        deleteSelectedButton.addTarget(self, action: #selector(tapDeleteSelected), for: .touchUpInside)
        deleteSelectedButton.isHidden = true

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavingsJarCell")

        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false

        let buttonRow = UIStackView(arrangedSubviews: [createButton, selectButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, buttonRow, deleteSelectedButton, tableView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(activity)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 48),
            deleteSelectedButton.heightAnchor.constraint(equalToConstant: 48),
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadJars() {
        activity.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await SavingsJarService.shared.getSavingsJars()
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.jars = result.filter { $0.status != "cancelled" }
                    self.selectedJarIds = self.selectedJarIds.intersection(Set(self.jars.map(\.id)))
                    self.tableView.backgroundView = self.jars.isEmpty ? self.makeEmptyView() : nil
                    self.tableView.reloadData()
                    self.updateSelectionUI()
                }
            } catch {
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func makeEmptyView() -> UIView {
        let label = UILabel()
        label.text = "Chưa có hũ tiết kiệm"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }

    @objc private func tapCreateJar() {
        navigationController?.pushViewController(CreateSavingsJarViewController(), animated: true)
    }

    @objc private func tapToggleSelectionMode() {
        isSelectingMultiple.toggle()
        if !isSelectingMultiple {
            selectedJarIds.removeAll()
        }
        tableView.setEditing(isSelectingMultiple, animated: true)
        updateSelectionUI()
        tableView.reloadData()
    }

    @objc private func tapDeleteSelected() {
        guard !selectedJarIds.isEmpty else {
            return showMessage(title: "Lỗi", message: "Vui lòng chọn ít nhất một quỹ để xoá")
        }

        let alert = UIAlertController(
            title: "Xoá nhiều quỹ",
            message: "Các quỹ còn số dư sẽ không thể xoá. Bạn có chắc chắn muốn tiếp tục?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xoá", style: .destructive) { [weak self] _ in
            self?.performBulkDelete()
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        jars.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavingsJarCell", for: indexPath)
        let jar = jars[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(jar.icon ?? "🐷") \(jar.name)"
        content.secondaryText = "\(Self.money(jar.currentAmount)) / \(Self.money(jar.targetAmount))"
        cell.contentConfiguration = content
        cell.accessoryType = isSelectingMultiple ? .none : .disclosureIndicator
        if isSelectingMultiple {
            cell.selectionStyle = .default
            cell.accessoryType = selectedJarIds.contains(jar.id) ? .checkmark : .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let jar = jars[indexPath.row]
        if isSelectingMultiple {
            if selectedJarIds.contains(jar.id) {
                selectedJarIds.remove(jar.id)
            } else {
                selectedJarIds.insert(jar.id)
            }
            updateSelectionUI()
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        navigationController?.pushViewController(SavingsJarDetailViewController(jarId: jar.id), animated: true)
    }

    private func updateSelectionUI() {
        selectButton.configuration?.title = isSelectingMultiple ? "Huỷ chọn" : "Chọn nhiều"
        deleteSelectedButton.isHidden = !isSelectingMultiple
        deleteSelectedButton.configuration?.title = selectedJarIds.isEmpty
            ? "Xoá quỹ đã chọn"
            : "Xoá \(selectedJarIds.count) quỹ đã chọn"
    }

    private func performBulkDelete() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await SavingsJarService.shared.deleteSavingsJarsBulk(ids: Array(self.selectedJarIds))
                await MainActor.run {
                    self.selectedJarIds.removeAll()
                    self.isSelectingMultiple = false
                    self.tableView.setEditing(false, animated: true)
                    self.updateSelectionUI()
                    self.showMessage(title: "Thành công", message: message)
                    self.loadJars()
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    fileprivate static func money(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "\(value) VND"
    }

    fileprivate static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()
}

final class CreateSavingsJarViewController: UIViewController {
    private let nameField = UITextField()
    private let targetAmountField = UITextField()
    private let deadlineField = UITextField()
    private let datePicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tạo quỹ"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        [nameField, targetAmountField, deadlineField].forEach {
            $0.borderStyle = .roundedRect
            $0.heightAnchor.constraint(equalToConstant: 46).isActive = true
        }
        nameField.placeholder = "Tên quỹ"
        targetAmountField.placeholder = "Số tiền mục tiêu"
        targetAmountField.keyboardType = .numberPad
        deadlineField.placeholder = "Thời hạn (tuỳ chọn)"

        datePicker.datePickerMode = .date
        datePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        deadlineField.inputView = datePicker
        deadlineField.inputAccessoryView = makeToolbar()

        let createButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Tạo mới"
        config.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        createButton.configuration = config
        createButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        createButton.addTarget(self, action: #selector(tapCreate), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [nameField, targetAmountField, deadlineField, createButton])
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

    private func makeToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(donePickingDate))
        ]
        return toolbar
    }

    @objc private func donePickingDate() {
        deadlineField.text = Self.deadlineFormatter.string(from: datePicker.date)
        deadlineField.resignFirstResponder()
    }

    @objc private func tapCreate() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let targetAmount = Double(targetAmountField.text ?? "") ?? 0
        guard !name.isEmpty else { return showMessage("Vui lòng nhập tên quỹ") }
        guard targetAmount >= 10000 else { return showMessage("Số tiền mục tiêu tối thiểu là 10,000₫") }

        let draft = SavingsJarDraft(
            name: name,
            targetAmount: targetAmount,
            deadline: deadlineField.text?.isEmpty == false ? deadlineField.text : nil,
            icon: "🐷"
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await SavingsJarService.shared.createSavingsJar(draft: draft)
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showMessage(error.localizedDescription)
                }
            }
        }
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static let deadlineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

final class SavingsJarDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let jarId: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activity = UIActivityIndicatorView(style: .medium)

    private var jar: SavingsJarItem?
    private var transactions: [WalletTransaction] = []

    init(jarId: String) {
        self.jarId = jarId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chi tiết quỹ"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Xoá",
            style: .plain,
            target: self,
            action: #selector(tapDeleteJar)
        )
        setupLayout()
        loadDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDetail()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16

        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.numberOfLines = 0
        amountLabel.font = .systemFont(ofSize: 20, weight: .bold)
        amountLabel.textColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)

        let depositButton = makeActionButton(title: "Góp quỹ", action: #selector(tapDeposit))
        let withdrawButton = makeActionButton(title: "Rút quỹ", action: #selector(tapWithdraw))
        let buttons = UIStackView(arrangedSubviews: [depositButton, withdrawButton])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        let historyTitle = UILabel()
        historyTitle.text = "Lịch sử góp/rút quỹ"
        historyTitle.font = .systemFont(ofSize: 18, weight: .bold)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavingsHistoryCell")
        tableView.isScrollEnabled = false
        tableView.heightAnchor.constraint(equalToConstant: 360).isActive = true
        tableView.layer.cornerRadius = 12

        activity.hidesWhenStopped = true

        [titleLabel, amountLabel, buttons, historyTitle, tableView, activity].forEach { contentStack.addArrangedSubview($0) }

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func loadDetail() {
        activity.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await SavingsJarService.shared.getSavingsJarDetail(id: self.jarId)
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.jar = detail.jar
                    self.transactions = detail.transactions
                    self.titleLabel.text = "\(detail.jar.icon ?? "🐷") \(detail.jar.name)"
                    self.amountLabel.text = "\(SavingsJarListViewController.money(detail.jar.currentAmount)) / \(SavingsJarListViewController.money(detail.jar.targetAmount))"
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        button.configuration = config
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func tapDeposit() {
        guard let jar else { return }
        navigationController?.pushViewController(SavingsJarAmountViewController(jar: jar, action: .deposit), animated: true)
    }

    @objc private func tapWithdraw() {
        guard let jar else { return }
        navigationController?.pushViewController(SavingsJarAmountViewController(jar: jar, action: .withdraw), animated: true)
    }

    @objc private func tapDeleteJar() {
        guard let jar else { return }
        let alert = UIAlertController(
            title: "Xoá quỹ",
            message: jar.currentAmount > 0
                ? "Quỹ vẫn còn số dư. Bạn cần rút hết tiền trước khi xoá."
                : "Bạn có chắc chắn muốn xoá quỹ này?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))

        guard jar.currentAmount <= 0 else {
            present(alert, animated: true)
            return
        }

        alert.addAction(UIAlertAction(title: "Xoá", style: .destructive) { [weak self] _ in
            self?.performDeleteJar()
        })
        present(alert, animated: true)
    }

    private func performDeleteJar() {
        guard let jar else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let message = try await SavingsJarService.shared.deleteSavingsJar(id: jar.id)
                await MainActor.run {
                    let alert = UIAlertController(title: "Thành công", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showMessage(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(transactions.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavingsHistoryCell", for: indexPath)
        guard !transactions.isEmpty else {
            var content = cell.defaultContentConfiguration()
            content.text = "Chưa có giao dịch"
            content.secondaryText = nil
            cell.contentConfiguration = content
            return cell
        }

        let transaction = transactions[indexPath.row]
        var content = cell.defaultContentConfiguration()
        let isDeposit = transaction.type == "savings_deposit"
        content.text = isDeposit ? "Góp quỹ" : "Rút quỹ"
        content.secondaryText = "\(SavingsJarListViewController.money(transaction.amount)) • \(Self.dateText(transaction.createdAt))"
        cell.contentConfiguration = content
        cell.accessoryView = {
            let label = UILabel()
            label.text = isDeposit ? "+" : "-"
            label.textColor = isDeposit ? .systemGreen : .systemOrange
            label.font = .systemFont(ofSize: 18, weight: .bold)
            return label
        }()
        return cell
    }

    private static func dateText(_ value: String?) -> String {
        guard let value else { return "—" }
        return value.replacingOccurrences(of: "T", with: " ").prefix(16).description
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class SavingsJarAmountViewController: UIViewController {
    private let jar: SavingsJarItem
    private let action: SavingsJarAction
    private let amountField = UITextField()

    init(jar: SavingsJarItem, action: SavingsJarAction) {
        self.jar = jar
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = action.title
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = action.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        amountField.placeholder = action == .deposit ? "Số tiền góp quỹ" : "Số tiền rút quỹ"
        amountField.borderStyle = .roundedRect
        amountField.keyboardType = .numberPad
        amountField.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let continueButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Tiếp tục"
        config.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        continueButton.configuration = config
        continueButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, amountField, continueButton])
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
        let amount = Double(amountField.text ?? "") ?? 0
        guard amount > 0 else { return showError("Vui lòng nhập số tiền hợp lệ") }
        let draft = SavingsJarActionDraft(jar: jar, amount: amount, action: action)
        navigationController?.pushViewController(SavingsJarConfirmViewController(draft: draft), animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class SavingsJarConfirmViewController: UIViewController {
    private let draft: SavingsJarActionDraft
    private let dimView = UIView()
    private let pinSheet = UIView()
    private let pinField = UITextField()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(draft: SavingsJarActionDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = draft.action.title
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        setupPinSheet()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = draft.action.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        let confirmButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Xác nhận"
        config.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        confirmButton.configuration = config
        confirmButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        confirmButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)

        let infoCard = UIStackView(arrangedSubviews: [
            makeRow(title: "Tên quỹ", value: draft.jar.name),
            makeRow(title: "Số tiền hiện tại", value: SavingsJarListViewController.money(draft.jar.currentAmount)),
            makeRow(title: "Mục tiêu", value: SavingsJarListViewController.money(draft.jar.targetAmount)),
            makeRow(title: "Số tiền", value: SavingsJarListViewController.money(draft.amount ?? 0))
        ])
        infoCard.axis = .vertical
        infoCard.spacing = 14
        infoCard.isLayoutMarginsRelativeArrangement = true
        infoCard.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        infoCard.backgroundColor = .secondarySystemGroupedBackground
        infoCard.layer.cornerRadius = 12
        infoCard.layer.masksToBounds = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, infoCard, confirmButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
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
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
    }

    private func setupPinSheet() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hidePinSheet)))

        pinSheet.backgroundColor = .systemBackground
        pinSheet.layer.cornerRadius = 18
        pinSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pinSheet.transform = CGAffineTransform(translationX: 0, y: 320)
        pinSheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinSheet)

        let titleLabel = UILabel()
        titleLabel.text = "Nhập mã PIN"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        pinField.placeholder = "PIN ví"
        pinField.keyboardType = .numberPad
        pinField.isSecureTextEntry = true
        pinField.textAlignment = .center
        pinField.font = .systemFont(ofSize: 22, weight: .semibold)
        pinField.borderStyle = .roundedRect
        pinField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let submitButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = draft.action.title
        config.baseBackgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        submitButton.configuration = config
        submitButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        submitButton.addTarget(self, action: #selector(tapSubmitPin), for: .touchUpInside)

        activity.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, pinField, submitButton, activity])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        pinSheet.addSubview(stack)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinSheet.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: pinSheet.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: pinSheet.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: pinSheet.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: pinSheet.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    @objc private func tapConfirm() {
        pinField.text = nil
        UIView.animate(withDuration: 0.25) {
            self.dimView.alpha = 1
            self.pinSheet.transform = .identity
        } completion: { _ in
            self.pinField.becomeFirstResponder()
        }
    }

    @objc private func hidePinSheet() {
        view.endEditing(true)
        UIView.animate(withDuration: 0.25) {
            self.dimView.alpha = 0
            self.pinSheet.transform = CGAffineTransform(translationX: 0, y: 320)
        }
    }

    @objc private func tapSubmitPin() {
        let pin = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard pin.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            return showMessage(title: "Lỗi", message: "PIN phải gồm đúng 6 chữ số")
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await SavingsJarService.shared.performAction(draft: self.draft, pin: pin)
                await MainActor.run {
                    self.setLoading(false)
                    self.hidePinSheet()
                    self.navigationController?.pushViewController(
                        SavingsJarResultViewController(draft: self.draft, result: result),
                        animated: true
                    )
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
        view.isUserInteractionEnabled = !loading
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

final class SavingsJarResultViewController: UIViewController {
    private let draft: SavingsJarActionDraft
    private let result: SavingsJarMutationData

    init(draft: SavingsJarActionDraft, result: SavingsJarMutationData) {
        self.draft = draft
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    private func setupLayout() {
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 76).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "\(draft.action.title) thành công"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        let amountLabel = UILabel()
        let actionAmount = draft.action == .deposit ? (result.depositAmount ?? draft.amount ?? 0) : (result.withdrawAmount ?? draft.amount ?? 0)
        amountLabel.text = SavingsJarListViewController.money(actionAmount)
        amountLabel.font = .systemFont(ofSize: 30, weight: .bold)
        amountLabel.textAlignment = .center

        let infoCard = UIStackView(arrangedSubviews: [
            makeRow(title: "Tên quỹ", value: draft.jar.name),
            makeRow(title: "Số dư ví", value: SavingsJarListViewController.money(result.walletBalance ?? 0)),
            makeRow(title: "Thời gian", value: Self.timeFormatter.string(from: Date()))
        ])
        infoCard.axis = .vertical
        infoCard.spacing = 14
        infoCard.isLayoutMarginsRelativeArrangement = true
        infoCard.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        infoCard.backgroundColor = .secondarySystemGroupedBackground
        infoCard.layer.cornerRadius = 12
        infoCard.layer.masksToBounds = true

        let detailButton = makeButton(title: "Quay lại chi tiết quỹ", filled: false)
        detailButton.addTarget(self, action: #selector(tapBackToDetail), for: .touchUpInside)

        let homeButton = makeButton(title: "Màn hình chính", filled: true)
        homeButton.addTarget(self, action: #selector(tapHome), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, amountLabel, infoCard, detailButton, homeButton])
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

    private func makeRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
    }

    private func makeButton(title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = filled ? UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1) : .secondarySystemGroupedBackground
        config.baseForegroundColor = filled ? .white : UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        config.cornerStyle = .large
        button.configuration = config
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return button
    }

    @objc private func tapBackToDetail() {
        navigationController?.popToViewController(
            navigationController?.viewControllers.first(where: { $0 is SavingsJarDetailViewController }) ?? self,
            animated: true
        )
    }

    @objc private func tapHome() {
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - dd/MM/yyyy"
        return formatter
    }()
}
