//
//  StudentVerificationReviewViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class StudentVerificationReviewViewController: UIViewController {

    private let draft: StudentVerificationDraft
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(draft: StudentVerificationDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Kiểm tra thông tin"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
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

        let titleLabel = UILabel()
        titleLabel.text = "Kiểm tra lần cuối"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Hãy chắc chắn thông tin bên dưới chính xác trước khi xác nhận."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8

        let infoSection = makeSection(rows: [
            ("Mã số sinh viên", draft.studentId),
            ("Họ và tên", draft.fullName),
            ("Ngày sinh", draft.dateOfBirth)
        ])

        let confirmButton = makePrimaryButton(title: "Xác nhận")
        confirmButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(infoSection)
        contentStack.addArrangedSubview(confirmButton)
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

    private func makeSection(rows: [(String, String)]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true

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
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        return container
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

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return separator
    }

    @objc private func tapConfirm() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.verifyStudent(
                    studentId: self.draft.studentId,
                    fullName: self.draft.fullName,
                    dateOfBirth: self.draft.dateOfBirth
                )
                await MainActor.run {
                    self.setLoading(false)
                    self.showSuccessAndReturnToProfile()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        view.isUserInteractionEnabled = !loading
        loading ? activity.startAnimating() : activity.stopAnimating()
    }

    private func showSuccessAndReturnToProfile() {
        let alert = UIAlertController(
            title: "Thành công",
            message: "Xác thực sinh viên thành công",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
