import Foundation

struct NotificationResponse: Codable {
    let success: Bool
    let data: [AppNotification]
}

struct AppNotification: Codable {
    let _id: String
    let title: String
    let message: String
    let type: String
    let link: String?
    let fileUrl: String?
    let isRead: Bool
    let createdAt: String
}
