//
//  TransactionService.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import Foundation

struct WalletTransaction: Decodable {
    let id: String
    let type: String
    let status: String
    let method: String?
    let amount: Double
    let description: String?
    let createdAt: String?
    let direction: String?
    let displayType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case type
        case status
        case method
        case amount
        case description
        case createdAt
        case direction
        case displayType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        type = try container.decode(String.self, forKey: .type)
        status = try container.decode(String.self, forKey: .status)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        amount = try container.decode(Double.self, forKey: .amount)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        direction = try container.decodeIfPresent(String.self, forKey: .direction)
        displayType = try container.decodeIfPresent(String.self, forKey: .displayType)
    }
}

struct TransactionPage: Decodable {
    let transactions: [WalletTransaction]
}

struct TransactionPageResponse: Decodable {
    let success: Bool
    let message: String?
    let data: TransactionPage?
}

struct ReceiverInfo: Decodable {
    let id: String
    let fullName: String
    let phone: String
    let studentId: String?
}

struct ReceiverResponse: Decodable {
    let success: Bool
    let message: String?
    let data: ReceiverInfo?
}

final class TransactionService {
    static let shared = TransactionService()
    private init() {}

    private let decoder = JSONDecoder()

    func getTransactions() async throws -> [WalletTransaction] {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getTransactions.urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(TransactionPageResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không lấy được lịch sử giao dịch")
        }

        if let decoded, decoded.success {
            return decoded.data?.transactions ?? []
        }

        throw AuthError.server(decoded?.message ?? "Không lấy được lịch sử giao dịch")
    }

    func lookupReceiver(query: String) async throws -> ReceiverInfo {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.lookupReceiver(query: query).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(ReceiverResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tìm thấy người nhận")
        }

        if let decoded, decoded.success, let receiver = decoded.data {
            return receiver
        }

        throw AuthError.server(decoded?.message ?? "Không tìm thấy người nhận")
    }

    func transfer(receiverId: String, amount: Double, description: String?, pin: String) async throws -> String {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.transfer(
            receiverId: receiverId,
            amount: amount,
            description: description,
            pin: pin
        ).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? JSONDecoder().decode(BasicResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Chuyển tiền thất bại")
        }

        return decoded?.message ?? "Chuyển tiền thành công"
    }
}
