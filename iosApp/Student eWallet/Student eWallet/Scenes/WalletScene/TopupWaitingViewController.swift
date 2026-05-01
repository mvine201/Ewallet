//
//  TopupWaitingViewController.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import UIKit

final class TopupWaitingViewController: UIViewController {

    private let amount: Double
    private let orderId: String
    private let paymentUrl: String
    private let statusLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .large)
    private var pollTimer: Timer?

    init(amount: Double, orderId: String, paymentUrl: String) {
        self.amount = amount
        self.orderId = orderId
        self.paymentUrl = paymentUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chờ thanh toán"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLayout() {
        activity.startAnimating()

        let titleLabel = UILabel()
        titleLabel.text = "Đang chờ VNPay xác nhận"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        statusLabel.text = "Hoàn tất thanh toán trên VNPay rồi quay lại app để kiểm tra kết quả."
        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        let checkButton = makeButton(title: "Kiểm tra kết quả", filled: true)
        checkButton.addTarget(self, action: #selector(tapCheckStatus), for: .touchUpInside)

        let reopenButton = makeButton(title: "Mở lại VNPay", filled: false)
        reopenButton.addTarget(self, action: #selector(tapOpenAgain), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [activity, titleLabel, statusLabel, checkButton, reopenButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeButton(title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        if filled {
            button.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
            button.tintColor = .white
        } else {
            button.backgroundColor = .secondarySystemGroupedBackground
            button.tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        }
        return button
    }

    private func startPolling() {
        checkStatus()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }

    @objc private func appWillEnterForeground() {
        checkStatus()
    }

    @objc private func tapCheckStatus() {
        checkStatus()
    }

    @objc private func tapOpenAgain() {
        if let url = URL(string: paymentUrl) {
            UIApplication.shared.open(url)
        }
    }

    private func checkStatus() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let status = try await WalletService.shared.getTopupStatus(orderId: self.orderId)
                await MainActor.run {
                    self.handle(status)
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = error.localizedDescription
                }
            }
        }
    }

    private func handle(_ status: TopupStatus) {
        switch status.status {
        case "success":
            pollTimer?.invalidate()
            let resultViewController = TopupResultViewController(
                amount: amount,
                orderId: orderId,
                paymentUrl: paymentUrl
            )
            if let navigationController {
                let walletRoot = navigationController.viewControllers.first { $0 is WalletViewController } ?? WalletViewController()
                navigationController.setViewControllers([walletRoot, resultViewController], animated: true)
            }
        case "failed":
            pollTimer?.invalidate()
            activity.stopAnimating()
            statusLabel.text = "Thanh toán thất bại hoặc đã bị huỷ."
        default:
            statusLabel.text = "Giao dịch đang chờ thanh toán. Mã giao dịch: \(orderId)"
        }
    }
}
