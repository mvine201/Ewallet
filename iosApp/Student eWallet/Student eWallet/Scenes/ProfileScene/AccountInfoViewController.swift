//
//  AccountInfoViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class AccountInfoViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Thông tin tài khoản"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadAccountInfo()
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

    private func loadAccountInfo() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let user = try await AuthService.shared.getMe()
                await MainActor.run {
                    self.setLoading(false)
                    self.render(user: user)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func render(user: AuthUser) {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        contentStack.addArrangedSubview(makeSection(
            title: "Tài khoản",
            rows: [
                ("Họ và tên", user.fullName),
                ("Số điện thoại", user.phone),
                ("Email", display(user.email, fallback: "Chưa cập nhật")),
                ("Trạng thái", user.isActive == false ? "Đã khoá" : "Đang hoạt động")
            ]
        ))

        let verifiedText = user.isVerified ? "Đã xác thực" : "Chưa xác thực"
        let studentInfo = user.studentInfo
        contentStack.addArrangedSubview(makeSection(
            title: "Thông tin sinh viên",
            rows: [
                ("Trạng thái", verifiedText),
                ("Mã số sinh viên", user.isVerified ? display(studentInfo?.studentId, fallback: "Chưa xác thực") : "Chưa xác thực"),
                ("Khoá", user.isVerified ? display(studentInfo?.cohort, fallback: "Chưa xác thực") : "Chưa xác thực"),
                ("Họ tên sinh viên", user.isVerified ? display(studentInfo?.fullName, fallback: "Chưa xác thực") : "Chưa xác thực"),
                ("Ngày sinh", user.isVerified ? display(studentInfo?.dateOfBirth ?? user.dateOfBirth, fallback: "Chưa xác thực") : "Chưa xác thực"),
                ("Khoa", user.isVerified ? display(studentInfo?.faculty, fallback: "Chưa xác thực") : "Chưa xác thực"),
                ("Tình trạng học", user.isVerified ? displayAcademicStatus(studentInfo?.academicStatus) : "Chưa xác thực"),
                ("Email sinh viên", user.isVerified ? display(studentInfo?.email, fallback: "Chưa xác thực") : "Chưa xác thực")
            ]
        ))
    }

    private func makeSection(title: String, rows: [(String, String)]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleContainer = UIView()
        titleContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -10)
        ])
        stack.addArrangedSubview(titleContainer)

        rows.enumerated().forEach { index, row in
            if index > 0 {
                stack.addArrangedSubview(makeSeparator())
            }
            stack.addArrangedSubview(makeInfoRow(title: row.0, value: row.1))
        }

        return stack
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let rowStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .firstBaseline

        let container = UIView()
        container.addSubview(rowStack)
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return separator
    }

    private func display(_ value: String?, fallback: String) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return value
    }

    private func displayAcademicStatus(_ value: String?) -> String {
        switch value {
        case "graduated":
            return "Đã tốt nghiệp"
        case "studying":
            return "Đang học"
        default:
            return "Chưa cập nhật"
        }
    }

    private func setLoading(_ loading: Bool) {
        if loading {
            contentStack.addArrangedSubview(activity)
            activity.startAnimating()
        } else {
            activity.stopAnimating()
            contentStack.removeArrangedSubview(activity)
            activity.removeFromSuperview()
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
