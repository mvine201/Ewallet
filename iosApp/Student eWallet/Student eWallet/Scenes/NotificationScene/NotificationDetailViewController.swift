import UIKit

class NotificationDetailViewController: UIViewController {

    let notification: AppNotification
    var onMarkRead: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let linkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mở đường dẫn đính kèm", for: .normal)
        button.setImage(UIImage(systemName: "link"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    private let fileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tải file đính kèm (.docx)", for: .normal)
        button.setImage(UIImage(systemName: "doc.text"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()

    init(notification: AppNotification) {
        self.notification = notification
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chi tiết thông báo"
        
        setupUI()
        configureData()
        markAsRead()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, dateLabel, messageLabel, linkButton, fileButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
        
        linkButton.addTarget(self, action: #selector(didTapLink), for: .touchUpInside)
        fileButton.addTarget(self, action: #selector(didTapFile), for: .touchUpInside)
    }
    
    private func configureData() {
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        
        // Format date string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: notification.createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            dateLabel.text = displayFormatter.string(from: date)
        } else {
            dateLabel.text = notification.createdAt
        }
        
        linkButton.isHidden = notification.link == nil || notification.link!.isEmpty
        fileButton.isHidden = notification.fileUrl == nil || notification.fileUrl!.isEmpty
    }
    
    @objc private func didTapLink() {
        if let linkString = notification.link, let url = URL(string: linkString) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func didTapFile() {
        if let fileString = notification.fileUrl, let url = URL(string: "https://ewallet-hn0m.onrender.com" + fileString) {
            UIApplication.shared.open(url) // Safari can download/open docx
        }
    }
    
    private func markAsRead() {
        guard !notification.isRead else { return }
        
        Task {
            do {
                _ = try await NetworkManager.shared.request(.markNotificationRead(id: notification._id))
                DispatchQueue.main.async {
                    self.onMarkRead?()
                }
            } catch {
                print("Failed to mark as read: \(error)")
            }
        }
    }
}
