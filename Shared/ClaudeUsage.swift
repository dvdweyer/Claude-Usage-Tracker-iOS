import Foundation

struct ClaudeUsage: Codable, Equatable {
    var sessionTokensUsed: Int
    var sessionLimit: Int
    var sessionPercentage: Double
    var sessionResetTime: Date

    var effectiveSessionPercentage: Double {
        sessionResetTime < Date() ? 0.0 : sessionPercentage
    }

    var weeklyTokensUsed: Int
    var weeklyLimit: Int
    var weeklyPercentage: Double
    var weeklyResetTime: Date

    var opusWeeklyTokensUsed: Int
    var opusWeeklyPercentage: Double

    var sonnetWeeklyTokensUsed: Int
    var sonnetWeeklyPercentage: Double
    var sonnetWeeklyResetTime: Date?

    var costUsed: Double?
    var costLimit: Double?
    var costCurrency: String?

    var overageBalance: Double?
    var overageBalanceCurrency: String?

    var lastUpdated: Date
    var userTimezone: TimeZone

    var remainingPercentage: Double {
        max(0, 100 - effectiveSessionPercentage)
    }

    static var empty: ClaudeUsage {
        ClaudeUsage(
            sessionTokensUsed: 0,
            sessionLimit: 0,
            sessionPercentage: 0,
            sessionResetTime: Date().addingTimeInterval(5 * 60 * 60),
            weeklyTokensUsed: 0,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 0,
            weeklyResetTime: Date().nextMonday1259pm(),
            opusWeeklyTokensUsed: 0,
            opusWeeklyPercentage: 0,
            sonnetWeeklyTokensUsed: 0,
            sonnetWeeklyPercentage: 0,
            sonnetWeeklyResetTime: nil,
            costUsed: nil,
            costLimit: nil,
            costCurrency: nil,
            overageBalance: nil,
            overageBalanceCurrency: nil,
            lastUpdated: Date(),
            userTimezone: .current
        )
    }
}

enum UsageStatusLevel {
    case safe
    case moderate
    case critical
}
