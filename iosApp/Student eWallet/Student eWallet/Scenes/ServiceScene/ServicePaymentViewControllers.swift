//
//  ServicePaymentViewControllers.swift
//  Student eWallet
//
//  Created by Assistant on 02/5/26.
//

import UIKit

final class ServiceListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activity = UIActivityIndicatorView(style: .medium)
    private let serviceType: String?
    private var services: [SchoolServiceItem] = []
    private var studentInfo: ServiceStudentInfo?

    init(serviceType: String? = nil) {
        self.serviceType = serviceType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thanh toán dịch vụ"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadServices()
    }

    private func setupLayout() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(activity)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadServices() {
        activity.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await ServicePaymentService.shared.getServices(type: self.serviceType)
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.studentInfo = data.studentInfo
                    self.services = data.services
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = services[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = "\(service.icon ?? "💳") \(service.name)"
        content.secondaryText = [
            Self.serviceTypeName(service.type),
            Self.currencyFormatter.string(from: NSNumber(value: displayAmount(for: service))) ?? "\(displayAmount(for: service)) VND",
            service.paymentStatus?.canPay == false ? "Đã thanh toán" : nil
        ].compactMap { $0 }.joined(separator: " • ")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let service = services[indexPath.row]
        if service.paymentStatus?.canPay == false {
            showMessage(title: "Đã thanh toán", message: "Bạn đã thanh toán dịch vụ này.")
            return
        }
        navigationController?.pushViewController(
            ServiceDetailViewController(service: service, student: studentInfo),
            animated: true
        )
    }

    private func displayAmount(for service: SchoolServiceItem) -> Double {
        if service.type == "parking" {
            return service.parkingConfig?.perUsePrice ?? service.price
        }
        return service.price
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static func serviceTypeName(_ type: String) -> String {
        switch type {
        case "tuition": return "Học phí"
        case "parking": return "Phí giữ xe"
        case "union_fee": return "Đoàn phí"
        case "library": return "Thư viện"
        case "dormitory": return "Ký túc xá"
        case "insurance": return "Bảo hiểm"
        case "canteen": return "Căn tin"
        default: return "Dịch vụ"
        }
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

final class ServiceDetailViewController: UIViewController {
    private let service: SchoolServiceItem
    private let student: ServiceStudentInfo?
    private let contentTextView = UITextView()
    private let modeControl = UISegmentedControl(items: ["Theo lượt", "Theo tháng"])
    private let amountLabel = UILabel()

    init(service: SchoolServiceItem, student: ServiceStudentInfo?) {
        self.service = service
        self.student = student
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chi tiết dịch vụ"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        updateContentForMode()
    }

    private func setupLayout() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16

        let titleLabel = UILabel()
        titleLabel.text = service.name
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 0

        amountLabel.font = .systemFont(ofSize: 24, weight: .bold)
        amountLabel.textColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)

        contentTextView.font = .systemFont(ofSize: 15)
        contentTextView.layer.cornerRadius = 10
        contentTextView.layer.borderWidth = 1
        contentTextView.layer.borderColor = UIColor.separator.cgColor
        contentTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let contentLabel = UILabel()
        contentLabel.text = "Nội dung thanh toán"
        contentLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        let continueButton = Self.makePrimaryButton(title: "Tiếp tục")
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(makeInfoCard())
        if service.type == "parking", service.parkingConfig?.monthlyPassEnabled == true {
            modeControl.selectedSegmentIndex = 0
            modeControl.addTarget(self, action: #selector(paymentModeChanged), for: .valueChanged)
            stack.addArrangedSubview(modeControl)
        }
        stack.addArrangedSubview(amountLabel)
        stack.addArrangedSubview(contentLabel)
        stack.addArrangedSubview(contentTextView)
        stack.addArrangedSubview(continueButton)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeInfoCard() -> UIView {
        let rows = [
            makeRow(title: "Dịch vụ", value: service.name),
            makeRow(title: "Mã sinh viên", value: student?.studentId ?? "Chưa xác thực"),
            makeRow(title: "Họ tên", value: student?.fullName ?? "Chưa xác thực"),
            makeRow(title: "Khoá", value: student?.cohort ?? "Chưa xác thực"),
            makeRow(title: "Khoa", value: student?.faculty ?? "Chưa xác thực"),
            makeRow(title: "Học kỳ", value: service.paymentWindow?.semester ?? "-"),
            makeRow(title: "Năm học", value: service.paymentWindow?.academicYear ?? "-")
        ]
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
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
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
    }

    @objc private func paymentModeChanged() {
        updateContentForMode()
    }

    private func updateContentForMode() {
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) VND"
        contentTextView.text = defaultContent
    }

    @objc private func tapContinue() {
        let content = contentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = ServicePaymentDraft(
            service: service,
            student: student,
            amount: amount,
            content: content.isEmpty ? defaultContent : content,
            paymentMode: paymentMode
        )
        navigationController?.pushViewController(
            ServicePaymentConfirmViewController(draft: draft),
            animated: true
        )
    }

    private var paymentMode: String {
        service.type == "parking" && modeControl.selectedSegmentIndex == 1 ? "monthly" : "single"
    }

    private var amount: Double {
        if service.type == "parking" {
            if paymentMode == "monthly" {
                return service.parkingConfig?.monthlyPassPrice ?? service.price
            }
            return service.parkingConfig?.perUsePrice ?? service.price
        }
        return service.price
    }

    private var defaultContent: String {
        let studentId = student?.studentId ?? "SINHVIEN"
        if service.type == "tuition" {
            let name = (student?.fullName ?? "SINH VIEN")
                .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
                .uppercased()
            return "\(name), \(studentId), thanh toán học phí kì \(service.paymentWindow?.semester ?? ""), năm học \(service.paymentWindow?.academicYear ?? "")"
        }
        if service.type == "parking", paymentMode == "monthly" {
            return "\(studentId) thanh toán phí giữ xe tháng \(Calendar.current.component(.month, from: Date()))"
        }
        if service.type == "parking" {
            return "\(studentId) thanh toán phí giữ xe vào lúc \(Self.timeFormatter.string(from: Date()))"
        }
        return "\(studentId) thanh toán \(service.name)"
    }

    private static func makePrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
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
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        return formatter
    }()
}

final class ServicePaymentConfirmViewController: UIViewController {
    private let draft: ServicePaymentDraft
    private let dimView = UIView()
    private let pinSheet = UIView()
    private let pinField = UITextField()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(draft: ServicePaymentDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Xác nhận"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        setupPinSheet()
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "Xác nhận thanh toán"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 0

        let confirmButton = makePrimaryButton(title: "Xác nhận")
        confirmButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, makeInfoCard(), confirmButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    private func makeInfoCard() -> UIView {
        let stack = UIStackView(arrangedSubviews: [
            makeRow(title: "Dịch vụ", value: draft.service.name),
            makeRow(title: "Mã sinh viên", value: draft.student?.studentId ?? "Chưa xác thực"),
            makeRow(title: "Người thanh toán", value: draft.student?.fullName ?? "Chưa xác thực"),
            makeRow(title: "Số tiền", value: Self.currencyFormatter.string(from: NSNumber(value: draft.amount)) ?? "\(draft.amount) VND"),
            makeRow(title: "Nội dung", value: draft.content)
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

        let submitButton = makePrimaryButton(title: "Xác nhận thanh toán")
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
            showMessage(title: "Lỗi", message: "PIN phải gồm đúng 6 chữ số")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let payment = try await ServicePaymentService.shared.payService(draft: self.draft, pin: pin)
                await MainActor.run {
                    self.setLoading(false)
                    self.hidePinSheet()
                    self.navigationController?.pushViewController(
                        ServicePaymentResultViewController(draft: self.draft, payment: payment),
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

    private func makePrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
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

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()
}

final class ServicePaymentResultViewController: UIViewController {
    private let draft: ServicePaymentDraft
    private let payment: PaidServiceInfo

    init(draft: ServicePaymentDraft, payment: PaidServiceInfo) {
        self.draft = draft
        self.payment = payment
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
        titleLabel.text = "Thanh toán thành công"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        let amountLabel = UILabel()
        amountLabel.text = Self.currencyFormatter.string(from: NSNumber(value: payment.amount)) ?? "\(payment.amount) VND"
        amountLabel.font = .systemFont(ofSize: 30, weight: .bold)
        amountLabel.textAlignment = .center

        let newButton = makeSecondaryButton(title: "Thanh toán dịch vụ khác")
        newButton.addTarget(self, action: #selector(tapNewPayment), for: .touchUpInside)

        let homeButton = makePrimaryButton(title: "Quay về trang chủ")
        homeButton.addTarget(self, action: #selector(tapHome), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [newButton, homeButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, amountLabel, makeInfoCard(), buttonStack])
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
            makeRow(title: "Dịch vụ", value: draft.service.name),
            makeRow(title: "Mã sinh viên", value: draft.student?.studentId ?? "Chưa xác thực"),
            makeRow(title: "Người thanh toán", value: draft.student?.fullName ?? "Chưa xác thực"),
            makeRow(title: "Nội dung", value: payment.content ?? draft.content),
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
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .firstBaseline
        return stack
    }

    @objc private func tapNewPayment() {
        guard let navigationController else { return }
        let root = navigationController.viewControllers.first ?? HomeViewController()
        navigationController.setViewControllers([root, ServiceListViewController()], animated: true)
    }

    @objc private func tapHome() {
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
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
