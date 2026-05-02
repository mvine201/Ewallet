//
//  APIEndpoint.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 13/4/26.
//

import Foundation
/// Centralized API endpoints for Student eWallet
enum APIEndpoint {
    // Auth
    case register(fullName: String, phone: String, password: String, email: String?)
    case login(phone: String, password: String)
    case verifyStudent(studentId: String, fullName: String, dateOfBirth: String)
    case changePassword(currentPassword: String, newPassword: String)
    case changePin(currentPin: String?, pin: String)
    case getMe
    case getMyWallet
    case createTopup(amount: Double, pin: String)
    case getTopupStatus(orderId: String)
    case getTransactions
    case lookupReceiver(query: String)
    case transfer(receiverId: String, amount: Double, description: String?, pin: String)
    case getPaymentServices(type: String?)
    case payService(serviceId: String, amount: Double?, content: String?, paymentMode: String, pin: String)
    case getNotifications
    case markNotificationRead(id: String)
}

// MARK: - Base URL
extension APIEndpoint {
    /// Configure your backend base URL here (no trailing slash)
    static var baseURL: URL { URL(string: "https://ewallet-hn0m.onrender.com")! }
}
// MARK: - Path
extension APIEndpoint {
    private static var apiPrefix: String { "/api" }

    var path: String {
        switch self {
        case .register:
            return "\(Self.apiPrefix)/auth/register"
        case .login:
            return "\(Self.apiPrefix)/auth/login"
        case .verifyStudent:
            return "\(Self.apiPrefix)/auth/verify-student"
        case .changePassword:
            return "\(Self.apiPrefix)/auth/change-password"
        case .changePin:
            return "\(Self.apiPrefix)/transfer/pin"
        case .getMe:
            return "\(Self.apiPrefix)/auth/me"
        case .getMyWallet:
            return "\(Self.apiPrefix)/wallet/me"
        case .createTopup:
            return "\(Self.apiPrefix)/wallet/topup"
        case let .getTopupStatus(orderId):
            return "\(Self.apiPrefix)/wallet/topup/status/\(orderId)"
        case .getTransactions:
            return "\(Self.apiPrefix)/wallet/transactions"
        case .lookupReceiver:
            return "\(Self.apiPrefix)/transfer/lookup"
        case .transfer:
            return "\(Self.apiPrefix)/transfer"
        case .getPaymentServices:
            return "\(Self.apiPrefix)/payments/services"
        case .payService:
            return "\(Self.apiPrefix)/payments/pay"
        case .getNotifications:
            return "\(Self.apiPrefix)/notifications"
        case let .markNotificationRead(id):
            return "\(Self.apiPrefix)/notifications/\(id)/read"
        }
    }
}

// MARK: - Method
extension APIEndpoint {
    var method: String {
        switch self {
        case .register, .login, .verifyStudent, .changePassword, .changePin, .createTopup, .transfer, .payService:
            return "POST"
        case .markNotificationRead:
            return "PUT"
        case .getMe, .getMyWallet, .getTopupStatus, .getTransactions, .lookupReceiver, .getPaymentServices, .getNotifications:
            return "GET"
        }
    }
}

// MARK: - Query
extension APIEndpoint {
    var queryItems: [URLQueryItem]? {
        switch self {
        case let .lookupReceiver(query):
            return [URLQueryItem(name: "q", value: query)]
        case let .getPaymentServices(type):
            guard let type, !type.isEmpty else { return nil }
            return [URLQueryItem(name: "type", value: type)]
        default:
            return nil
        }
    }
}

// MARK: - Body
extension APIEndpoint {
    /// JSON body for endpoints that require it
    var jsonBody: [String: Any]? {
        switch self {
        case let .register(fullName, phone, password, email):
            var body: [String: Any] = [
                "fullName": fullName,
                "phone": phone,
                "password": password
            ]
            if let email, !email.isEmpty { body["email"] = email }
            return body
        case let .login(phone, password):
            return [
                "phone": phone,
                "password": password
            ]
        case let .verifyStudent(studentId, fullName, dateOfBirth):
            return [
                "studentId": studentId,
                "fullName": fullName,
                "dateOfBirth": dateOfBirth
            ]
        case let .changePassword(currentPassword, newPassword):
            return [
                "currentPassword": currentPassword,
                "newPassword": newPassword
            ]
        case let .changePin(currentPin, pin):
            var body: [String: Any] = [
                "pin": pin
            ]
            if let currentPin, !currentPin.isEmpty {
                body["currentPin"] = currentPin
            }
            return body
        case let .createTopup(amount, pin):
            return [
                "amount": amount,
                "pin": pin
            ]
        case let .transfer(receiverId, amount, description, pin):
            var body: [String: Any] = [
                "receiverId": receiverId,
                "amount": amount,
                "pin": pin
            ]
            if let description, !description.isEmpty {
                body["description"] = description
            }
            return body
        case let .payService(serviceId, amount, content, paymentMode, pin):
            var body: [String: Any] = [
                "serviceId": serviceId,
                "paymentMode": paymentMode,
                "pin": pin
            ]
            if let amount {
                body["amount"] = amount
            }
            if let content, !content.isEmpty {
                body["content"] = content
            }
            return body
        case .getMe, .getMyWallet, .getTopupStatus, .getTransactions, .lookupReceiver, .getPaymentServices, .getNotifications, .markNotificationRead:
            return nil
        }
    }
}

// MARK: - URLRequest builder
extension APIEndpoint {
    func urlRequest(token: String? = nil) throws -> URLRequest {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        if let body = jsonBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        return request
    }
}
