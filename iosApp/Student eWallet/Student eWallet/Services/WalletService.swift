//
//  WalletService.swift
//  Student eWallet
//
//  Created by Assistant on 29/4/26.
//

import Foundation

struct TopupData: Decodable {
    let paymentUrl: String
    let orderId: String
}

struct TopupResponse: Decodable {
    let success: Bool
    let message: String?
    let data: TopupData?
}

struct TopupStatus: Decodable {
    let orderId: String
    let amount: Double
    let status: String
    let responseCode: String?
    let bankCode: String?
    let payDate: String?
}

struct TopupStatusResponse: Decodable {
    let success: Bool
    let message: String?
    let data: TopupStatus?
}

final class WalletService {
    static let shared = WalletService()
    private init() {}

    private let decoder = JSONDecoder()

    func createTopup(amount: Double, pin: String) async throws -> TopupData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.createTopup(amount: amount, pin: pin).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(TopupResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Tạo yêu cầu nạp tiền thất bại")
        }

        if let decoded, decoded.success, let topup = decoded.data {
            return topup
        }

        throw AuthError.server(decoded?.message ?? "Tạo yêu cầu nạp tiền thất bại")
    }

    func getTopupStatus(orderId: String) async throws -> TopupStatus {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getTopupStatus(orderId: orderId).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(TopupStatusResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không kiểm tra được trạng thái nạp tiền")
        }

        if let decoded, decoded.success, let status = decoded.data {
            return status
        }

        throw AuthError.server(decoded?.message ?? "Không kiểm tra được trạng thái nạp tiền")
    }
}
