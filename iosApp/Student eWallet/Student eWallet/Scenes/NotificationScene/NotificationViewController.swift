//
//  NotificationViewController.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 2/5/26.
//

import UIKit

class NotificationViewController: UIViewController {

    private let tableView = UITableView()
    private var notifications: [AppNotification] = []
    
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Thông báo"
        
        setupTableView()
        fetchNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNotifications() // Reload in case we read a notification
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        refreshControl.addTarget(self, action: #selector(fetchNotifications), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func fetchNotifications() {
        Task {
            do {
                guard let token = TokenStore.shared.token else { return }
                let request = try APIEndpoint.getNotifications.urlRequest(token: token)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                let decoder = JSONDecoder()
                let result = try decoder.decode(NotificationResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.notifications = result.data
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    // Show error
                    let alert = UIAlertController(title: "Lỗi", message: "Không thể tải thông báo", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "NotificationCell")
        let notification = notifications[indexPath.row]
        
        cell.textLabel?.text = notification.title
        cell.detailTextLabel?.text = notification.message
        cell.detailTextLabel?.numberOfLines = 2
        
        if !notification.isRead {
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            cell.detailTextLabel?.textColor = .label
        } else {
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            cell.detailTextLabel?.textColor = .secondaryLabel
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = notifications[indexPath.row]
        let detailVC = NotificationDetailViewController(notification: notification)
        detailVC.onMarkRead = { [weak self] in
            // Update local state to read without full refetch if we want, or just wait for viewWillAppear
            if let index = self?.notifications.firstIndex(where: { $0._id == notification._id }) {
                // Since AppNotification is a struct, we can't mutate its property directly unless we recreate it.
                // Let viewWillAppear handle the refetch to be safe and simple.
            }
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
