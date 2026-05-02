//
//  ServicePaymentService.swift
//  Student eWallet
//
//  Created by Assistant on 02/5/26.
//

import Foundation

struct ServiceStudentInfo: Decodable {
    let studentId: String?
    let fullName: String?
    let cohort: String?
    let faculty: String?
    let email: String?
    let academicStatus: String?
}

struct ServicePaymentStatus: Decodable {
    let hasPaid: Bool?
    let hasUnpaid: Bool?
    let canPay: Bool?
}

struct ServicePaymentWindow: Decodable {
    let startAt: String?
    let endAt: String?
    let semester: String?
    let academicYear: String?
}

struct ServiceParkingConfig: Decodable {
    let perUsePrice: Double?
    let monthlyPassEnabled: Bool?
    let monthlyPassPrice: Double?
    let monthlyPassOpenDayFrom: Int?
    let monthlyPassOpenDayTo: Int?
}

struct SchoolServiceItem: Decodable {
    let id: String
    let name: String
    let price: Double
    let description: String?
    let category: String?
    let type: String
    let icon: String?
    let paymentWindow: ServicePaymentWindow?
    let parkingConfig: ServiceParkingConfig?
    let paymentStatus: ServicePaymentStatus?

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case name
        case price
        case description
        case category
        case type
        case icon
        case paymentWindow
        case parkingConfig
        case paymentStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        type = try container.decode(String.self, forKey: .type)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        paymentWindow = try container.decodeIfPresent(ServicePaymentWindow.self, forKey: .paymentWindow)
        parkingConfig = try container.decodeIfPresent(ServiceParkingConfig.self, forKey: .parkingConfig)
        paymentStatus = try container.decodeIfPresent(ServicePaymentStatus.self, forKey: .paymentStatus)
    }
}

struct PaymentServicesData: Decodable {
    let services: [SchoolServiceItem]
    let studentInfo: ServiceStudentInfo?
}

struct PaymentServicesResponse: Decodable {
    let success: Bool
    let message: String?
    let data: PaymentServicesData?
}

struct PaidServiceInfo: Decodable {
    let amount: Double
    let content: String?
    let paidAt: String?
    let transactionId: String?
}

struct PayServiceData: Decodable {
    let payment: PaidServiceInfo?
    let walletBalance: Double?
}

struct PayServiceResponse: Decodable {
    let success: Bool
    let message: String?
    let data: PayServiceData?
}

struct ServicePaymentDraft {
    let service: SchoolServiceItem
    let student: ServiceStudentInfo?
    let amount: Double
    let content: String
    let paymentMode: String
}

final class ServicePaymentService {
    static let shared = ServicePaymentService()
    private init() {}

    private let decoder = JSONDecoder()

    func getServices(type: String? = nil) async throws -> PaymentServicesData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getPaymentServices(type: type).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(PaymentServicesResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tải được danh sách dịch vụ")
        }

        if let decoded, decoded.success, let data = decoded.data {
            return data
        }

        throw AuthError.server(decoded?.message ?? "Không tải được danh sách dịch vụ")
    }

    func payService(draft: ServicePaymentDraft, pin: String) async throws -> PaidServiceInfo {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.payService(
            serviceId: draft.service.id,
            amount: draft.amount,
            content: draft.content,
            paymentMode: draft.paymentMode,
            pin: pin
        ).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(PayServiceResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Thanh toán dịch vụ thất bại")
        }

        if let decoded, decoded.success, let payment = decoded.data?.payment {
            return payment
        }

        throw AuthError.server(decoded?.message ?? "Thanh toán dịch vụ thất bại")
    }
}
