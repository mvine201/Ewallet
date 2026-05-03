import Foundation

enum StatisticsPeriod: String {
    case week
    case month

    var title: String {
        switch self {
        case .week: return "Tuần"
        case .month: return "Tháng"
        }
    }
}

struct AnalyticsCategory: Decodable {
    let key: String
    let title: String
    let colorHex: String
    let bucket: String
    let amount: Double
    let percentage: Double
    let transactionCount: Int
}

struct AnalyticsDailyPoint: Decodable {
    let date: String
    let amount: Double
}

struct AnalyticsSummary: Decodable {
    let topCategoryTitle: String?
    let topCategoryAmount: Double
    let topCategoryPercentage: Double
    let transactionCount: Int
}

struct AnalyticsStatsData: Decodable {
    let period: String
    let startDate: String
    let endDate: String
    let totalExpense: Double
    let totalInflow: Double
    let netCashFlow: Double
    let categories: [AnalyticsCategory]
    let daily: [AnalyticsDailyPoint]
    let summary: AnalyticsSummary
}

struct AnalyticsStatsResponse: Decodable {
    let success: Bool
    let message: String?
    let data: AnalyticsStatsData?
}

struct AnalyticsAIAction: Decodable {
    let title: String
    let detail: String
    let tag: String
    let emphasis: String
}

struct AnalyticsAIMetrics: Decodable {
    let stabilityScore: Int
    let needsRate: Int
    let wantsRate: Int
    let savingsRate: Int
}

struct AnalyticsAIPlanData: Decodable {
    let period: String
    let generatedAt: String
    let status: String
    let headline: String
    let summary: String
    let focusLabel: String
    let focusValue: String
    let actions: [AnalyticsAIAction]
    let badges: [String]
    let metrics: AnalyticsAIMetrics
    let source: String
}

struct AnalyticsAIPlanResponse: Decodable {
    let success: Bool
    let message: String?
    let data: AnalyticsAIPlanData?
}

final class StatisticsService {
    static let shared = StatisticsService()
    private init() {}

    private let decoder = JSONDecoder()

    func getStats(period: StatisticsPeriod) async throws -> AnalyticsStatsData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getAnalyticsStats(period: period.rawValue).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(AnalyticsStatsResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tải được thống kê chi tiêu")
        }

        if let result = decoded?.data {
            return result
        }

        throw AuthError.server(decoded?.message ?? "Không tải được thống kê chi tiêu")
    }

    func getAIPlan(period: StatisticsPeriod) async throws -> AnalyticsAIPlanData {
        guard let token = TokenStore.shared.token else { throw AuthError.server("Chưa đăng nhập") }
        let request = try APIEndpoint.getAnalyticsAIPlan(period: period.rawValue).urlRequest(token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        let decoded = try? decoder.decode(AnalyticsAIPlanResponse.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw AuthError.server(decoded?.message ?? "Không tải được gợi ý AI")
        }

        if let result = decoded?.data {
            return result
        }

        throw AuthError.server(decoded?.message ?? "Không tải được gợi ý AI")
    }
}
