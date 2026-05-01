//
//  StudentVerificationViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

struct StudentVerificationDraft {
    let studentId: String
    let fullName: String
    let dateOfBirth: String
}

final class StudentVerificationViewController: UIViewController, UITextFieldDelegate {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let datePicker = UIDatePicker()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Xác thực sinh viên"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Nhập thông tin đúng theo hồ sơ sinh viên để hệ thống đối chiếu."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let studentIdField = StudentVerificationViewController.makeTextField(
        placeholder: "Mã số sinh viên"
    )

    private let fullNameField = StudentVerificationViewController.makeTextField(
        placeholder: "Họ và tên sinh viên"
    )

    private let dateOfBirthField = StudentVerificationViewController.makeTextField(
        placeholder: "Ngày sinh"
    )

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tiếp tục", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Xác thực"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        setupDatePicker()
        setupActions()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 8, right: 0)

        [studentIdField, fullNameField, dateOfBirthField].forEach { field in
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
        }

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(studentIdField)
        contentStack.addArrangedSubview(fullNameField)
        contentStack.addArrangedSubview(dateOfBirthField)
        contentStack.addArrangedSubview(continueButton)

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

    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        dateOfBirthField.inputView = datePicker
        dateOfBirthField.inputAccessoryView = makeDatePickerToolbar()
    }

    private func setupActions() {
        studentIdField.delegate = self
        fullNameField.delegate = self
        dateOfBirthField.delegate = self
        studentIdField.autocapitalizationType = .allCharacters
        fullNameField.autocapitalizationType = .words
        continueButton.addTarget(self, action: #selector(tapContinue), for: .touchUpInside)
    }

    private func makeDatePickerToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(donePickingDate))
        ]
        return toolbar
    }

    @objc private func donePickingDate() {
        dateOfBirthField.text = Self.dateFormatter.string(from: datePicker.date)
        dateOfBirthField.resignFirstResponder()
    }

    @objc private func tapContinue() {
        view.endEditing(true)

        let studentId = studentIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fullName = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dateOfBirth = dateOfBirthField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !studentId.isEmpty else {
            showError("Vui lòng nhập mã số sinh viên")
            return
        }

        guard !fullName.isEmpty else {
            showError("Vui lòng nhập họ và tên sinh viên")
            return
        }

        guard dateOfBirth.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            showError("Vui lòng chọn ngày sinh")
            return
        }

        let draft = StudentVerificationDraft(
            studentId: studentId,
            fullName: fullName,
            dateOfBirth: dateOfBirth
        )
        let reviewViewController = StudentVerificationReviewViewController(draft: draft)
        navigationController?.pushViewController(reviewViewController, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === studentIdField {
            fullNameField.becomeFirstResponder()
        } else if textField === fullNameField {
            dateOfBirthField.becomeFirstResponder()
        } else {
            tapContinue()
        }
        return true
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static func makeTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        return textField
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
