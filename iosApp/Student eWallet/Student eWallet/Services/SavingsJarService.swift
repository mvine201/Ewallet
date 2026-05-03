import Foundation

struct SavingsJarItem: Decodable {
    let id: String
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: String?
    let icon: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case name
        case targetAmount
        case currentAmount
        case deadline
        case icon
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        name = try container.decode(String.self, forKey: .name)
        targetAmount = try container.decodeIfPresent(Double.self, forKey: .targetAmount) ?? 0
        currentAmount = try container.decodeIfPresent(Double.self, forKey: .currentAmount) ?? 0
        deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
    }
}

struct SavingsJarListResponse: Decodable {
    let success: Bool
    let message: String?
    let data: [SavingsJarItem]
}

struct SavingsJarDetailData: Decodable {
    let jar: SavingsJarItem
    let transactions: [WalletTransaction]
}

struct SavingsJarDetailResponse: Decodable {
    let success: Bool
    let message: String?
    let data: SavingsJarDetailData?
}

struct SavingsJarMutationData: Decodable {
    let jar: SavingsJarItem?
    let walletBalance: Double?
    let depositAmount: Double?
    let withdrawAmount: Double?
}

struct SavingsJarMutationResponse: Decodable {
    let success: Bool
    let message: String?
    let data: SavingsJarMutationData?
}

struct SavingsJarCreateResponse: Decodable {
    let success: Bool
    let message: String?
    let data: SavingsJarItem?
}

struct SavingsJarDraft {
    let name: String
    let targetAmount: Double
    let deadline: String?
    let icon: String?
}

struct SavingsJarActionDraft {
    let jar: SavingsJarItem
    let amount: Double?
    let action: SavingsJarAction
}

enum SavingsJarAction {
    case deposit
    case withdraw

    var title: String {
        switch self {
        case .deposit: return "Góp quỹ"
        case .withdraw: return "Rút quỹ"
        }
    }
}

final class SavingsJarService {
    static let shared = SavingsJarService()
    private init() {}

    private let decoder = JSONDecoder()

    func getSavingsJars() async throws -> [SavingsJarItem] {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getSavingsJars.urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(SavingsJarListResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tải được danh sách quỹ tiết kiệm")
        }

        return decoded?.data ?? []
    }

    func getSavingsJarDetail(id: String) async throws -> SavingsJarDetailData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getSavingsJarDetail(id: id).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(SavingsJarDetailResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tải được chi tiết quỹ tiết kiệm")
        }

        if let detail = decoded?.data {
            return detail
        }
        throw AuthError.server(decoded?.message ?? "Không tải được chi tiết quỹ tiết kiệm")
    }

    func createSavingsJar(draft: SavingsJarDraft) async throws -> SavingsJarItem {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.createSavingsJar(
            name: draft.name,
            targetAmount: draft.targetAmount,
            deadline: draft.deadline,
            icon: draft.icon
        ).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(SavingsJarCreateResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Tạo quỹ tiết kiệm thất bại")
        }

        if let jar = decoded?.data {
            return jar
        }
        throw AuthError.server(decoded?.message ?? "Tạo quỹ tiết kiệm thất bại")
    }

    func performAction(draft: SavingsJarActionDraft, pin: String) async throws -> SavingsJarMutationData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }

        let endpoint: APIEndpoint
        switch draft.action {
        case .deposit:
            endpoint = .depositSavingsJar(id: draft.jar.id, amount: draft.amount ?? 0, pin: pin)
        case .withdraw:
            endpoint = .withdrawSavingsJar(id: draft.jar.id, amount: draft.amount, pin: pin)
        }

        let request = try endpoint.urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(SavingsJarMutationResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "\(draft.action.title) thất bại")
        }

        if let result = decoded?.data {
            return result
        }
        throw AuthError.server(decoded?.message ?? "\(draft.action.title) thất bại")
    }

    func deleteSavingsJar(id: String) async throws -> String {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.deleteSavingsJar(id: id).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(BasicResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Xoá quỹ thất bại")
        }

        return decoded?.message ?? "Đã xoá quỹ"
    }
}
