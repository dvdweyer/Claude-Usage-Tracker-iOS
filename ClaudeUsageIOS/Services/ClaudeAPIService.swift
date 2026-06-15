import Foundation

final class ClaudeAPIService {
    static let shared = ClaudeAPIService()
    private let sessionKeyValidator = SessionKeyValidator()
    private init() {}

    // MARK: - Public API

/// Fetches usage data for a profile, returning usage and the org ID that was used
    /// (which may have been auto-resolved if not yet stored in the profile).
    func fetchUsageDataWithOrgId(for profile: Profile) async throws -> (usage: ClaudeUsage, orgId: String) {
        guard let sessionKey = profile.claudeSessionKey else {
            throw AppError(
                code: .sessionKeyNotFound,
                message: "No session key configured for this profile.",
                isRecoverable: true,
                recoverySuggestion: "Add a session key in profile settings."
            )
        }

        let orgId: String
        if let stored = profile.organizationId {
            orgId = stored
        } else {
            let orgs = try await fetchOrganizations(sessionKey: sessionKey)
            guard let first = orgs.first else {
                throw AppError(code: .apiParsingFailed, message: "No organizations found for this account.", isRecoverable: false)
            }
            orgId = first.uuid
        }

        let usage = try await fetchUsageData(sessionKey: sessionKey, organizationId: orgId)
        return (usage: usage, orgId: orgId)
    }

    /// Fetches usage + overage data for a known org ID.
    func fetchUsageData(sessionKey: String, organizationId: String) async throws -> ClaudeUsage {
        async let usageTask = performRequest(
            endpoint: "/organizations/\(organizationId)/usage",
            sessionKey: sessionKey
        )
        async let overageTask: Data? = {
            do { return try await performRequest(endpoint: "/organizations/\(organizationId)/overage_spend_limit", sessionKey: sessionKey) }
            catch { return nil }
        }()
        async let creditTask: Data? = {
            do { return try await performRequest(endpoint: "/organizations/\(organizationId)/overage_credit_grant", sessionKey: sessionKey) }
            catch { return nil }
        }()

        let usageData = try await usageTask
        var usage = try parseUsageResponse(usageData)

        if let overageData = await overageTask,
           let overage = try? JSONDecoder().decode(OverageSpendLimitResponse.self, from: overageData),
           overage.isEnabled == true {
            usage.costUsed = overage.usedCredits.map { $0 / 100.0 }
            usage.costLimit = overage.monthlyCreditLimit.map { $0 / 100.0 }
            usage.costCurrency = overage.currency
        }

        if let creditData = await creditTask,
           let grant = try? JSONDecoder().decode(OverageCreditGrantResponse.self, from: creditData) {
            usage.overageBalance = grant.remainingBalance.map { $0 / 100.0 }
            usage.overageBalanceCurrency = grant.currency
        }

        return usage
    }

    /// Validates a session key and returns the organizations it has access to.
    func testSessionKey(_ key: String) async throws -> [AccountInfo] {
        let validated = try sessionKeyValidator.validate(key)
        return try await fetchOrganizations(sessionKey: validated)
    }

    func fetchOrganizations(sessionKey: String) async throws -> [AccountInfo] {
        let url = try URLBuilder.claudeAPI(endpoint: "/organizations").build()
        var request = sessionRequest(url: url, sessionKey: sessionKey)
        request.httpMethod = "GET"

        let (data, response) = try await execute(request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid server response.", isRecoverable: true)
        }

        switch http.statusCode {
        case 200:
            let orgs = try JSONDecoder().decode([AccountInfo].self, from: data)
            guard !orgs.isEmpty else {
                throw AppError(code: .apiParsingFailed, message: "No organizations found.", isRecoverable: false)
            }
            return orgs
        case 401, 403:
            throw AppError(
                code: .apiUnauthorized,
                message: "Session key is invalid or has expired.",
                isRecoverable: true,
                recoverySuggestion: "Update your session key in profile settings."
            )
        case 429:
            throw AppError(code: .apiRateLimited, message: "Too many requests. Please wait and try again.", isRecoverable: true)
        default:
            throw AppError(code: .apiGenericError, message: "Server returned HTTP \(http.statusCode).", isRecoverable: true)
        }
    }

    // MARK: - Private

    private func performRequest(endpoint: String, sessionKey: String) async throws -> Data {
        let url = try URLBuilder(baseURL: Constants.APIEndpoints.claudeBase)
            .appendingPath(endpoint)
            .build()
        var request = sessionRequest(url: url, sessionKey: sessionKey)
        request.httpMethod = "GET"

        let (data, response) = try await execute(request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid server response.", isRecoverable: true)
        }

        switch http.statusCode {
        case 200: return data
        case 401, 403:
            throw AppError(
                code: .apiUnauthorized,
                message: "Session key is invalid or has expired.",
                isRecoverable: true,
                recoverySuggestion: "Update your session key in profile settings."
            )
        case 429:
            throw AppError(code: .apiRateLimited, message: "Too many requests. Please wait.", isRecoverable: true)
        case 500...599:
            throw AppError(code: .apiServerError, message: "Claude server error (HTTP \(http.statusCode)).", isRecoverable: true)
        default:
            throw AppError(code: .apiGenericError, message: "Unexpected response: HTTP \(http.statusCode).", isRecoverable: true)
        }
    }

    private func sessionRequest(url: URL, sessionKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://claude.ai", forHTTPHeaderField: "Referer")
        request.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        request.timeoutInterval = 30
        return request
    }

    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw AppError(
                code: .networkGenericError,
                message: "Network request failed.",
                technicalDetails: error.localizedDescription,
                underlyingError: error,
                isRecoverable: true,
                recoverySuggestion: "Check your internet connection and try again."
            )
        }
    }

    // MARK: - Response Parsing

    private func parseUsageResponse(_ data: Data) throws -> ClaudeUsage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError(code: .apiParsingFailed, message: "Failed to parse usage data.", isRecoverable: false)
        }

        var sessionPercentage = 0.0
        var sessionResetTime = Date().addingTimeInterval(5 * 3600)
        if let fiveHour = json["five_hour"] as? [String: Any] {
            if let util = fiveHour["utilization"] { sessionPercentage = parseUtilization(util) }
            if let resetsAt = fiveHour["resets_at"] as? String {
                sessionResetTime = ISO8601DateFormatter.fractional.date(from: resetsAt) ?? sessionResetTime
            }
        }

        var weeklyPercentage = 0.0
        var weeklyResetTime = Date().nextMonday1259pm()
        if let sevenDay = json["seven_day"] as? [String: Any] {
            if let util = sevenDay["utilization"] { weeklyPercentage = parseUtilization(util) }
            if let resetsAt = sevenDay["resets_at"] as? String {
                weeklyResetTime = ISO8601DateFormatter.fractional.date(from: resetsAt) ?? weeklyResetTime
            }
        }

        var opusPercentage = 0.0
        if let sevenDayOpus = json["seven_day_opus"] as? [String: Any],
           let util = sevenDayOpus["utilization"] {
            opusPercentage = parseUtilization(util)
        }

        var sonnetPercentage = 0.0
        var sonnetResetTime: Date?
        if let sevenDaySonnet = json["seven_day_sonnet"] as? [String: Any] {
            if let util = sevenDaySonnet["utilization"] { sonnetPercentage = parseUtilization(util) }
            if let resetsAt = sevenDaySonnet["resets_at"] as? String {
                sonnetResetTime = ISO8601DateFormatter.fractional.date(from: resetsAt)
            }
        }

        let limit = Constants.weeklyLimit
        return ClaudeUsage(
            sessionTokensUsed: 0,
            sessionLimit: 0,
            sessionPercentage: sessionPercentage,
            sessionResetTime: sessionResetTime,
            weeklyTokensUsed: Int(Double(limit) * weeklyPercentage / 100.0),
            weeklyLimit: limit,
            weeklyPercentage: weeklyPercentage,
            weeklyResetTime: weeklyResetTime,
            opusWeeklyTokensUsed: Int(Double(limit) * opusPercentage / 100.0),
            opusWeeklyPercentage: opusPercentage,
            sonnetWeeklyTokensUsed: Int(Double(limit) * sonnetPercentage / 100.0),
            sonnetWeeklyPercentage: sonnetPercentage,
            sonnetWeeklyResetTime: sonnetResetTime,
            costUsed: nil,
            costLimit: nil,
            costCurrency: nil,
            overageBalance: nil,
            overageBalanceCurrency: nil,
            lastUpdated: Date(),
            userTimezone: .current
        )
    }

    private func parseUtilization(_ value: Any) -> Double {
        if let i = value as? Int { return Double(i) }
        if let d = value as? Double { return d }
        if let s = value as? String {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")) ?? 0
        }
        return 0
    }
}

// MARK: - API Response Types

extension ClaudeAPIService {
    struct AccountInfo: Codable {
        let uuid: String
        let name: String
        let capabilities: [String]
    }

    struct OverageSpendLimitResponse: Codable {
        let monthlyCreditLimit: Double?
        let currency: String?
        let usedCredits: Double?
        let isEnabled: Bool?

        enum CodingKeys: String, CodingKey {
            case monthlyCreditLimit = "monthly_credit_limit"
            case currency
            case usedCredits = "used_credits"
            case isEnabled = "is_enabled"
        }
    }

    struct OverageCreditGrantResponse: Codable {
        let remainingBalance: Double?
        let currency: String?

        enum CodingKeys: String, CodingKey {
            case remainingBalance = "remaining_balance"
            case currency
        }
    }
}

private extension ISO8601DateFormatter {
    static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
