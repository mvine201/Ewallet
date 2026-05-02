//
//  AuthService.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 13/4/26.
//

import Foundation

// MARK: - Models
struct AuthUser: Decodable {
    let id: String
    let fullName: String
    let phone: String
    let email: String?
    let role: String?
    let isActive: Bool?
    let isVerified: Bool
    let studentId: String?
    let studentFullName: String?
    let dateOfBirth: String?
    let avatar: String?
    let studentInfo: StudentInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case fullName
        case phone
        case email
        case role
        case isActive
        case isVerified
        case studentId
        case studentFullName
        case dateOfBirth
        case avatar
        case studentInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? "Người dùng"
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        studentId = try container.decodeIfPresent(String.self, forKey: .studentId)
        studentFullName = try container.decodeIfPresent(String.self, forKey: .studentFullName)
        dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        studentInfo = try container.decodeIfPresent(StudentInfo.self, forKey: .studentInfo)
    }
}

struct StudentInfo: Decodable {
    let studentId: String
    let fullName: String
    let dateOfBirth: String?
    let email: String?
    let cohort: String?
    let faculty: String?
    let academicStatus: String?
}

struct AuthResponse: Decodable {
    let success: Bool
    let message: String?
    let data: AuthData?
}

struct AuthData: Decodable {
    let token: String?
    let user: AuthUser?
}

struct CurrentUserResponse: Decodable {
    let success: Bool
    let message: String?
    let data: AuthUser?
}

struct BasicResponse: Decodable {
    let success: Bool
    let message: String?
}

struct WalletInfo: Decodable {
    let id: String
    let balance: Double
    let currency: String
    let status: String
    let hasPin: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case balance
        case currency
        case status
        case hasPin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoId)
        balance = try container.decode(Double.self, forKey: .balance)
        currency = try container.decode(String.self, forKey: .currency)
        status = try container.decode(String.self, forKey: .status)
        hasPin = try container.decode(Bool.self, forKey: .hasPin)
    }
}

struct WalletResponse: Decodable {
    let success: Bool
    let message: String?
    let data: WalletInfo?
}

// MARK: - Errors
enum AuthError: Error, LocalizedError {
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(let msg): return msg
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

// MARK: - Token Store (in-memory only)
final class TokenStore {
    static let shared = TokenStore()
    private init() {}
    var token: String?
    func clear() { token = nil }
}

// MARK: - AuthService
final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private func serverMessage(from data: Data, statusCode: Int?, defaultMessage: String) -> String {
        if let decoded = try? decoder.decode(AuthResponse.self, from: data), let msg = decoded.message, !msg.isEmpty {
            return msg
        }
        if let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }
        if let code = statusCode {
            return "\(defaultMessage) (\(code))"
        }
        return defaultMessage
    }

    // Login
    func login(phone: String, password: String) async throws {
        let request = try APIEndpoint.login(phone: phone, password: password).urlRequest()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Đăng nhập thất bại")
            throw AuthError.server(message)
        }

        do {
            let decoded = try decoder.decode(AuthResponse.self, from: data)
            if decoded.success, let token = decoded.data?.token {
                let role = decoded.data?.user?.role ?? "user"
                guard role == "user" else {
                    TokenStore.shared.clear()
                    throw AuthError.server("Đăng nhập không hợp lệ")
                }
                TokenStore.shared.token = token
            } else {
                let message = decoded.message ?? "Đăng nhập thất bại"
                throw AuthError.server(message)
            }
        } catch {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Phản hồi máy chủ không đúng định dạng")
            throw AuthError.server(message)
        }
    }

    // Register (do not auto-login)
    func register(fullName: String, phone: String, password: String, email: String?) async throws {
        let request = try APIEndpoint.register(fullName: fullName, phone: phone, password: password, email: email).urlRequest()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        // Treat 2xx as success; avoid failing on decoding when server returns plain text or a different schema
        if (200..<300).contains(http.statusCode) {
            if let decoded = try? decoder.decode(AuthResponse.self, from: data), decoded.success == false {
                throw AuthError.server(decoded.message ?? "Đăng ký thất bại")
            }
            return
        } else {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Đăng ký thất bại")
            throw AuthError.server(message)
        }
    }

    // Verify student (requires token)
    func verifyStudent(studentId: String, fullName: String, dateOfBirth: String) async throws {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.verifyStudent(
            studentId: studentId,
            fullName: fullName,
            dateOfBirth: dateOfBirth
        ).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Xác thực sinh viên thất bại")
            throw AuthError.server(message)
        }

        if let decoded = try? decoder.decode(AuthResponse.self, from: data), decoded.success == false {
            throw AuthError.server(decoded.message ?? "Xác thực sinh viên thất bại")
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws -> String {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        ).urlRequest(token: token)
        return try await performBasicRequest(request, defaultMessage: "Đổi mật khẩu thất bại")
    }

    func changePin(currentPin: String?, pin: String) async throws -> String {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.changePin(currentPin: currentPin, pin: pin).urlRequest(token: token)
        return try await performBasicRequest(request, defaultMessage: "Đổi PIN thất bại")
    }

    func getMyWallet() async throws -> WalletInfo {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getMyWallet.urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Không lấy được thông tin ví")
            throw AuthError.server(message)
        }

        let decoded = try decoder.decode(WalletResponse.self, from: data)
        if decoded.success, let wallet = decoded.data {
            return wallet
        }

        throw AuthError.server(decoded.message ?? "Không lấy được thông tin ví")
    }

    // Get current user
    func getMe() async throws -> AuthUser {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getMe.urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }

        if !(200..<300).contains(http.statusCode) {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Không lấy được thông tin người dùng")
            throw AuthError.server(message)
        }

        do {
            let decoded = try decoder.decode(CurrentUserResponse.self, from: data)
            if decoded.success, let user = decoded.data {
                return user
            } else {
                let message = decoded.message ?? "Không lấy được thông tin người dùng"
                throw AuthError.server(message)
            }
        } catch {
            let message = serverMessage(from: data, statusCode: http.statusCode, defaultMessage: "Phản hồi máy chủ không đúng định dạng")
            throw AuthError.server(message)
        }
    }

    private func performBasicRequest(_ request: URLRequest, defaultMessage: String) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(BasicResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            let message = decoded?.message ?? serverMessage(
                from: data,
                statusCode: http.statusCode,
                defaultMessage: defaultMessage
            )
            throw AuthError.server(message)
        }

        if let decoded, decoded.success {
            return decoded.message ?? "Thành công"
        }

        throw AuthError.server(decoded?.message ?? defaultMessage)
    }
}
