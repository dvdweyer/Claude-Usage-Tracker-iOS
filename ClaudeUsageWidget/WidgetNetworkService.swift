import Foundation

enum WidgetNetworkService {
    static func fetchUsage(sessionKey: String, orgId: String) async -> ClaudeUsage? {
        guard let url = URL(string: "https://claude.ai/api/organizations/\(orgId)/usage") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://claude.ai", forHTTPHeaderField: "Referer")
        request.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        request.timeoutInterval = 20

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        return parseUsage(data)
    }

    private static func parseUsage(_ data: Data) -> ClaudeUsage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        var sessionPercentage = 0.0
        var sessionResetTime = Date().addingTimeInterval(5 * 3600)
        if let fiveHour = json["five_hour"] as? [String: Any] {
            if let util = fiveHour["utilization"] { sessionPercentage = parseUtilization(util) }
            if let resetsAt = fiveHour["resets_at"] as? String {
                sessionResetTime = iso8601.date(from: resetsAt) ?? sessionResetTime
            }
        }

        var weeklyPercentage = 0.0
        var weeklyResetTime = Date().nextMonday1259pm()
        if let sevenDay = json["seven_day"] as? [String: Any] {
            if let util = sevenDay["utilization"] { weeklyPercentage = parseUtilization(util) }
            if let resetsAt = sevenDay["resets_at"] as? String {
                weeklyResetTime = iso8601.date(from: resetsAt) ?? weeklyResetTime
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
                sonnetResetTime = iso8601.date(from: resetsAt)
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

    private static func parseUtilization(_ value: Any) -> Double {
        if let i = value as? Int { return Double(i) }
        if let d = value as? Double { return d }
        if let s = value as? String {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")) ?? 0
        }
        return 0
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
